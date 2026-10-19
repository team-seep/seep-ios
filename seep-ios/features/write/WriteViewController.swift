import Foundation
import UIKit
import Combine

import CombineCocoa
import RxSwift
import ReactorKit

protocol WriteDelegate: AnyObject {
    func onSuccessWrite(category: Category)
}

final class WriteViewController: BaseVC, View, WriteCoordinator {
    weak var delegate: WriteDelegate?
    private let writeView = WriteView()
    private let writeReactor: WriteReactor
    private let stepsViewModel = WishStepsViewModel(config: .init(mode: .draft(steps: [], screenName: .write)))
    private let linkViewModel: WishLinkViewModel
    private let placeViewModel: WishPlaceViewModel
    private var cancellables = Set<AnyCancellable>()
    private weak var coordinator: WriteCoordinator?
    private var isKeyboardShown = false
    
    private let datePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.locale = .init(identifier: "ko_KO")
    }
    
    init(category: Category) {
        self.writeReactor = WriteReactor(
            category: category,
            wishService: WishService(),
            userDefaults: UserDefaultsUtils(),
            notificationManager: NotificationManager.shared
        )
        self.linkViewModel = WishLinkViewModel(config: .init(mode: .write, category: category))
        self.placeViewModel = WishPlaceViewModel(config: .init(mode: .draft(category: category, screenName: .write)))
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func instance(category: Category) -> WriteViewController {
        return WriteViewController(category: category).then {
            $0.modalPresentationStyle = .overCurrentContext
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func loadView() {
        self.view = WideScreenContainerView(contentView: self.writeView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // 폴더블 접기/펴기·회전으로 창 폭이 바뀌면 해시태그 줄바꿈을 새 폭으로 다시 계산한다
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.writeView.hashtagCollectionView.collectionViewLayout.invalidateLayout()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.writeReactor
        self.coordinator = self
        self.setupKeyboardNotification()
        self.writeView.dateField.inputView = self.datePicker
        self.writeView.categoryView.moveActiveButton(category: self.writeReactor.currentState.category)
        self.bindSteps()
        self.bindTargetAmount()
        self.bindLink()
        self.bindPlace()
    }
    
    override func bindEvent() {
        self.writeView.closeButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.writeView.tapBackground.rx.event
            .asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.writeView.endEditing(true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.writeView.accessoryView.finishButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.writeView.endEditing(true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.writeReactor.pushNotificationPublisher
            .asDriver(onErrorJustReturn: ([], nil))
            .drive(onNext: { [weak self] (notifications, selectedIndex) in
                self?.coordinator?.pushNotification(
                    totalNotifications: notifications,
                    selectedIndex: selectedIndex
                )
            })
            .disposed(by: self.eventDisposeBag)
        
        self.writeReactor.dismissWishCategoryPublisher
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { [weak self] category in
                self?.delegate?.onSuccessWrite(category: category)
                self?.coordinator?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: WriteReactor) {
        // MARK: Action
        self.writeView.emojiInputView.rx.emoji
            .map { Reactor.Action.inputEmoji($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.categoryView.rx.tapCategory
            .map { Reactor.Action.tapCategory($0) }
            .do(onNext: { _ in
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
                
        self.writeView.titleField.rx.text.orEmpty
            .map { Reactor.Action.inputTitle($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.dateSwitch.rx.value
            .map { Reactor.Action.tapDeadlineSwitch($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.datePicker.rx.date
            .skip(1) // 초기값을 바로 전달해서 하나 스킵합니다.
            .do(onNext: { [weak self] deadline in
                let dateString = DateUtils.toString(
                    format: "yyyy년 MM월 dd일 eeee 까지",
                    date: deadline.endOfDay
                )
                
                self?.writeView.dateField.textField.text = dateString
            })
            .map { Reactor.Action.inputDeadline($0.endOfDay) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.dateSwitch.rx.value
            .map { Reactor.Action.tapDeadlineSwitch($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.notificationSwitch.rx.value
            .map { Reactor.Action.tapNotificationSwitch($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.addNotificationButton.rx.tap
            .map { Reactor.Action.tapAddNotificationButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.memoField.rx.text.orEmpty
            .filter { $0 != "wrtie_placeholder_memo".localized }
            .map { Reactor.Action.inputMemo($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.hashtagCollectionView.rx.itemSelected
            .map { Reactor.Action.tapHashtag(index: $0.row) }
            .do(onNext: { [weak self] _ in
                self?.writeView.endEditing(true)
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.hashtagField.rx.text.orEmpty
            .distinctUntilChanged()
            .do(onNext: { [weak self] text in
                if !text.isEmpty {
                    self?.writeView.hashtagCollectionView.deselectAllItems(animated: true)
                }
            })
            .map { Reactor.Action.inputHashtag($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.writeButton.rx.tap
            .map { Reactor.Action.tapWriteButton }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // MARK: State
        reactor.state
            .map { $0.isTooltipShown }
            .asDriver(onErrorJustReturn: true)
            .distinctUntilChanged()
            .filter { $0 == false }
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.writeView.emojiInputView.showRandomEmojiTooltip()
                self.writeReactor.action.onNext(.tooltipDisappeared)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.category }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { [weak self] category in
                self?.writeView.setTitlePlaceholder(by: category)
            })
            .disposed(by: self.disposeBag)
                
        reactor.state
            .map { $0.titleError }
            .distinctUntilChanged()
            .skip(1)
            .asDriver(onErrorJustReturn: nil)
            .drive(self.writeView.titleField.rx.errorMessage)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.deadlineError }
            .distinctUntilChanged()
            .skip(1)
            .asDriver(onErrorJustReturn: nil)
            .drive(self.writeView.dateField.rx.errorMessage)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isDeadlineEnable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.writeView.dateField.rx.isDateEnable)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { state in
                return state.notifications.map { ($0, state.isNotificationEnable) }
            }
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { [weak self] (notificationsWithEnable) in
                self?.writeView.updateNotificationTableViewHeight(by: notificationsWithEnable)
            })
            .drive(self.writeView.notificationTableView.rx.items(
                    cellIdentifier: WriteNotificationTableViewCell.registerId,
                    cellType: WriteNotificationTableViewCell.self
            )) { row, notification, cell in
                cell.bind(notification: notification.0, isEnable: notification.1)
                cell.rx.tap
                    .map { Reactor.Action.tapEditNotification(index: row) }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isNotificationEnable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.writeView.rx.isNotificationEnable)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.hashtags }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(self.writeView.hashtagCollectionView.rx.items(
                    cellIdentifier: HashtagCollectionViewCell.registerID,
                    cellType: HashtagCollectionViewCell.self
            )) { row, hashtagType, cell in
                cell.bind(type: hashtagType)
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.customHashtag }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(self.writeView.hashtagField.rx.setText)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.writeButtonState }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .initial)
            .drive(self.writeView.writeButton.rx.state)
            .disposed(by: self.disposeBag)
    }
    
    private func setupKeyboardNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        guard let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardFrame.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        self.writeView.scrollView.contentInset.bottom = keyboardViewEndFrame.height
        self.writeView.scrollView.scrollIndicatorInsets = self.writeView.scrollView.contentInset
        self.isKeyboardShown = true
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        self.writeView.scrollView.contentInset.bottom = .zero
        self.isKeyboardShown = false
    }
}

// MARK: Link
extension WriteViewController {
    /// 링크 칸 (GH-29 R-1~R-3, R-6). 링크는 Reactor 상태로만 넘겨 작성 완료 때 함께 저장된다.
    private func bindLink() {
        let linkView = writeView.linkView

        linkView.textPublisher
            .subscribe(linkViewModel.input.inputText)
            .store(in: &cancellables)

        linkView.pastePublisher
            .subscribe(linkViewModel.input.paste)
            .store(in: &cancellables)

        writeReactor.state
            .map { $0.category }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] category in
                self?.linkViewModel.input.changeCategory.send(category)
            })
            .disposed(by: eventDisposeBag)

        linkViewModel.output.isVisible
            .main
            .sink { isVisible in
                linkView.setCollapsed(!isVisible)
            }
            .store(in: &cancellables)

        linkViewModel.output.text
            .main
            .sink { text in
                linkView.setText(text)
            }
            .store(in: &cancellables)

        linkViewModel.output.errorMessage
            .main
            .sink { errorMessage in
                linkView.bind(errorMessage: errorMessage)
            }
            .store(in: &cancellables)

        linkViewModel.output.preview
            .main
            .sink { preview in
                linkView.bind(preview: preview)
            }
            .store(in: &cancellables)

        linkViewModel.output.linkInput
            .withUnretained(self)
            .sink { (owner: WriteViewController, link: WishLinkInput) in
                owner.writeReactor.action.onNext(.inputLink(link))
            }
            .store(in: &cancellables)

        linkViewModel.input.viewDidLoad.send(())
    }
}

// MARK: Target amount
extension WriteViewController {
    /// 목표 금액 입력 (GH-16 R-1·R-2). 갖고 싶어요일 때만 펼치고, 금액은 Reactor 상태로만 넘겨 저장 때 함께 저장된다.
    private func bindTargetAmount() {
        let targetAmountView = writeView.targetAmountView
        targetAmountView.amountPublisher
            .withUnretained(self)
            .sink { (owner: WriteViewController, amount: Int) in
                owner.writeReactor.action.onNext(.inputTargetAmount(amount))
            }
            .store(in: &cancellables)

        writeReactor.state
            .map { $0.category }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { category in
                targetAmountView.setCollapsed(category != .wantToGet)
            })
            .disposed(by: eventDisposeBag)
    }
}

// MARK: Place
extension WriteViewController {
    /// 장소 (GH-31 R-1·R-4). 가고 싶어요일 때만 펼치고, 장소는 Reactor 상태로만 넘겨 작성 완료 때 위시와 함께 저장된다.
    private func bindPlace() {
        let placeView = writeView.placeView

        placeView.tapPlacePublisher
            .withUnretained(self)
            .sink { (owner: WriteViewController, _) in
                owner.writeView.endEditing(true)
                owner.placeViewModel.input.didTapPlace.send(())
            }
            .store(in: &cancellables)

        placeView.deletePlacePublisher
            .subscribe(placeViewModel.input.didTapDelete)
            .store(in: &cancellables)

        placeViewModel.output.isVisible
            .main
            .sink { isVisible in
                placeView.setCollapsed(!isVisible)
            }
            .store(in: &cancellables)

        placeViewModel.output.emoji
            .main
            .sink { emoji in
                placeView.bind(emoji: emoji)
            }
            .store(in: &cancellables)

        placeViewModel.output.place
            .main
            .sink { place in
                placeView.bind(place: place)
            }
            .store(in: &cancellables)

        placeViewModel.output.didUpdatePlace
            .withUnretained(self)
            .sink { (owner: WriteViewController, place: WishPlace?) in
                owner.writeReactor.action.onNext(.inputPlace(place))
            }
            .store(in: &cancellables)

        placeViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WriteViewController, route: WishPlaceViewModel.Route) in
                owner.handlePlaceRoute(route)
            }
            .store(in: &cancellables)

        writeReactor.state
            .map { $0.category }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] category in
                self?.placeViewModel.input.updateCategory.send(category)
            })
            .disposed(by: eventDisposeBag)

        writeReactor.state
            .map { $0.emoji }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] emoji in
                self?.placeViewModel.input.updateEmoji.send(emoji)
            })
            .disposed(by: eventDisposeBag)
    }

    private func handlePlaceRoute(_ route: WishPlaceViewModel.Route) {
        switch route {
        case .presentPlaceSearch(let viewModel):
            presentPanModal(PlaceSearchBottomSheetViewController(viewModel: viewModel))
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
}

// MARK: Steps
extension WriteViewController {
    /// 작성 화면의 단계 섹션 (GH-5 R-13~R-17). 단계는 저장하지 않고 Reactor 상태로만 넘겨, 작성 완료 때 위시와 함께 저장된다.
    private func bindSteps() {
        let stepsView = writeView.stepsView

        stepsView.addButton.tapPublisher
            .subscribe(stepsViewModel.input.didTapAdd)
            .store(in: &cancellables)

        stepsView.deleteStepPublisher
            .subscribe(stepsViewModel.input.deleteStep)
            .store(in: &cancellables)

        stepsViewModel.output.steps
            .main
            .sink { steps in
                stepsView.bind(steps: steps)
            }
            .store(in: &cancellables)

        stepsViewModel.output.progress
            .main
            .sink { progress in
                stepsView.bind(progress: progress)
            }
            .store(in: &cancellables)

        stepsViewModel.output.isAddEnabled
            .main
            .sink { isAddEnabled in
                stepsView.bind(isAddEnabled: isAddEnabled)
            }
            .store(in: &cancellables)

        stepsViewModel.output.didUpdateSteps
            .withUnretained(self)
            .sink { (owner: WriteViewController, steps: [WishStep]) in
                owner.writeReactor.action.onNext(.updateSteps(steps))
            }
            .store(in: &cancellables)

        stepsViewModel.output.toast
            .main
            .sink { message in
                ToastManager.shared.show(message: message)
            }
            .store(in: &cancellables)

        stepsViewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WriteViewController, route: WishStepsViewModel.Route) in
                owner.handleStepsRoute(route)
            }
            .store(in: &cancellables)
    }

    private func handleStepsRoute(_ route: WishStepsViewModel.Route) {
        switch route {
        case .presentAddStepInput:
            presentAddWishStepAlert { [weak self] title in
                self?.stepsViewModel.input.addStep.send(title)
            }
        case .showErrorAlert(let error):
            AlertUtils.show(viewController: self, title: nil, message: error.localizedDescription)
        }
    }
}

extension WriteViewController: NotificationViewControllerDelegate {
    func onDeleteNotification(index: Int) {
        self.writeReactor.action.onNext(.deleteNotification(index: index))
    }
    
    func onEditNotification(index: Int, notification: SeepNotification) {
        self.writeReactor.action.onNext(
            .updateNotification(index: index, notification: notification)
        )
    }
    
    func onAddNotification(notification: SeepNotification) {
        self.writeReactor.action.onNext(.addNotification(notification))
    }
}
