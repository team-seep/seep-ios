import UIKit

import RxSwift
import ReactorKit

protocol WishDetailDelegate: AnyObject {
    func onUpdateCategory(category: Category)
}

enum DetailMode {
    case fromHome
    case fromFinish
}

final class WishDetailViewController: BaseVC, View, WishDetailCoordinator {
    weak var delegate: WishDetailDelegate?
    private let wishDetailView = WishDetailView()
    private let wishDetailReactor: WishDetailReactor
    private weak var coordinator: WishDetailCoordinator?
    fileprivate let wish: Wish
    private let mode: DetailMode
    private let datePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.locale = .init(identifier: "ko_KO")
    }
    
    init(wish: Wish, mode: DetailMode) {
        self.wishDetailReactor = WishDetailReactor(
            wish: wish,
            wishService: WishService()
        )
        self.wish = wish
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static func instance(wish: Wish, mode: DetailMode) -> WishDetailViewController {
        return WishDetailViewController(wish: wish, mode: mode)
    }
    
    override func loadView() {
        self.view = self.wishDetailView
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.wishDetailReactor
        self.coordinator = self
        self.setupKeyboardNotification()
        self.wishDetailView.dateField.inputView = self.datePicker
        self.wishDetailView.containerView.isUserInteractionEnabled = self.mode == .fromHome
    }
  
    override func bindEvent() {
        self.wishDetailView.tapBackground.rx.event
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.wishDetailView.endEditing(true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailView.moreButton.rx.tap
            .asDriver()
            .compactMap { [weak self] in
                return self?.mode
            }
            .drive(onNext: { [weak self] mode in
                guard let self = self else { return }
                self.coordinator?.showActionSheet(
                    mode: self.mode,
                    onTapShare: {
                        self.wishDetailReactor.action.onNext(.tapSharePhoto)
                    },
                    onTapDelete: {
                        self.wishDetailReactor.action.onNext(.tapDeleteButton)
                    },
                    onTapCancelFinish: {
                        self.wishDetailReactor.action.onNext(.tapCancelFinish)
                    })
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailView.accessoryView.finishButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.wishDetailView.endEditing(true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailView.backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailReactor.popupWithCategoryPublisher
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { [weak self] category in
                self?.delegate?.onUpdateCategory(category: category)
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailReactor.presentSharePhotoPublisher
            .asDriver(onErrorJustReturn: Wish())
            .drive(onNext: { [weak self] wish in
                self?.coordinator?.presentSharePhoto(wish: wish)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishDetailReactor.pushNotificationPublisher
            .asDriver(onErrorJustReturn: ([], nil))
            .drive(onNext: { [weak self] (notifications, index)in
                let notifications = notifications.compactMap { $0 }
                
                if !(notifications.isEmpty && index == 0) {
                    self?.coordinator?.pushNotification(totalNotifications: notifications, selectedIndex: index)
                }
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: WishDetailReactor) {
        // MARK: Action
        self.wishDetailView.cancelButton.rx.tap
            .map { Reactor.Action.tapCancelButton }
            .do(onNext: { [weak self] _ in
                self?.wishDetailView.endEditing(true)
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    
        self.wishDetailView.emojiInputView.rx.emoji
            .skip(1)
            .map { Reactor.Action.inputEmoji($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.emojiInputView.rx.controlEvent(.editingDidBegin)
            .map { Reactor.Action.tapEditButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.categoryView.rx.tapCategory
            .map { Reactor.Action.tapCategory($0) }
            .do(onNext: { _ in
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    
        self.wishDetailView.titleField.rx.text.orEmpty
            .skip(1)
            .map { Reactor.Action.inputTitle($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.titleField.rx.controlEvent(.editingDidBegin)
            .map { Reactor.Action.tapEditButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    
        self.datePicker.rx.date
            .skip(1)
            .map { Reactor.Action.inputDeadline($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    
        self.wishDetailView.dateField.textField.rx.controlEvent(.editingDidBegin)
            .map { Reactor.Action.tapEditButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.dateSwitch.rx.isOn
            .skip(1)
            .map { Reactor.Action.tapDeadlineSwitch($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.addNotificationButton.rx.tap
            .map { Reactor.Action.tapAddNotificationButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    
        self.wishDetailView.notificationSwitch.rx.isOn
            .skip(1)
            .map { Reactor.Action.tapNotificationSwitch($0) }
            .do(onNext: { _ in
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.memoField.rx.text.orEmpty
            .filter { $0 != "wrtie_placeholder_memo".localized && $0 != "detail_memo_empty".localized }
            .map { Reactor.Action.inputMemo($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.memoField.rx.didBeginEditing
            .map { Reactor.Action.tapEditButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.hashtagCollectionView.rx.itemSelected
            .map { _ in Reactor.Action.tapEditButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishDetailView.hashtagField.rx.text.orEmpty
            .skip(1)
            .distinctUntilChanged()
            .do(onNext: { [weak self] text in
                if !text.isEmpty {
                    self?.wishDetailView.hashtagCollectionView.deselectAllItems(animated: true)
                }
            })
            .map { Reactor.Action.inputHashtag($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    
        self.wishDetailView.hashtagField.rx.controlEvent(.editingDidBegin)
            .map { Reactor.Action.tapEditButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    
        self.wishDetailView.editButton.rx.tap
            .map { Reactor.Action.tapSaveButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // MARK: State
        reactor.state
            .map { $0.isEditable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.wishDetailView.rx.isEditable)
            .disposed(by: self.disposeBag)
    
        reactor.state
            .map { $0.emoji }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] emoji in
                self?.wishDetailView.emojiInputView.setEmoji(emoji: emoji)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.category }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { [weak self] category in
                self?.wishDetailView.categoryView.moveActiveButton(category: category)
                self?.wishDetailView.setTitlePlaceholder(by: category)
            })
            .disposed(by: self.disposeBag)
    
        reactor.state
            .map { $0.title }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] title in
                self?.wishDetailView.titleField.setText(text: title)
            })
            .disposed(by: self.disposeBag)

        reactor.state
            .map { $0.titleError }
            .asDriver(onErrorJustReturn: nil)
            .drive(self.wishDetailView.titleField.rx.errorMessage)
            .disposed(by: self.disposeBag)

        reactor.state
            .map { ($0.deadline, $0.isEditable) }
            .asDriver(onErrorJustReturn: (nil, false))
            .drive(onNext: { [weak self] (deadline, isEditable) in
                if let deadline = deadline {
                    let deadlineText = DateUtils.toString(format: "yyyy년 MM월 dd일 eeee 까지", date: deadline)
                    
                    self?.wishDetailView.dateField.setText(text: deadlineText)
                } else {
                    self?.wishDetailView.dateField.placeholder = isEditable
                        ? "write_placeholder_date_enable".localized
                        : "write_placeholder_date_disable".localized
                }
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.deadlineError }
            .asDriver(onErrorJustReturn: nil)
            .drive(self.wishDetailView.dateField.rx.errorMessage)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isDeadlineEnable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.wishDetailView.dateSwitch.rx.isOn)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isDeadlineEnable }
            .asDriver(onErrorJustReturn: false)
            .drive(self.wishDetailView.dateField.rx.isDateEnable)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { state in
                return state.notifications.map { ($0, state.isNotificationEnable) }
            }
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { [weak self] (notificationsWithEnable) in
                self?.wishDetailView.updateNotificationTableViewHeight(by: notificationsWithEnable)
            })
            .drive(self.wishDetailView.notificationTableView.rx.items(
                    cellIdentifier: WriteNotificationTableViewCell.registerId,
                    cellType: WriteNotificationTableViewCell.self
            )) { row, notification, cell in
                cell.bind(notification: notification.0, isEnable: notification.1)
                cell.rx.tap
                    .map { Reactor.Action.tapEditNotification(index: row) }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
                
                cell.rx.tap
                    .map { Reactor.Action.tapHashtag(index: row) }
                    .do(onNext: { [weak self] _ in
                        self?.wishDetailView.endEditing(true)
                    })
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isNotificationEnable }
            .asDriver(onErrorJustReturn: false)
            .drive(self.wishDetailView.rx.isNotificationEnable)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.hashtags }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(self.wishDetailView.hashtagCollectionView.rx.items(
                    cellIdentifier: HashtagCollectionViewCell.registerID,
                    cellType: HashtagCollectionViewCell.self
            )) { row, hashtagType, cell in
                cell.bind(type: hashtagType)
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .compactMap { $0.selectedHashtag }
            .distinctUntilChanged()
            .compactMap { hashtag in HashtagType.array.firstIndex(of: hashtag) }
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] index in
                self?.wishDetailView.selectHashTag(index: index)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.customHashtag }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(self.wishDetailView.hashtagField.rx.setText)
            .disposed(by: self.disposeBag)
    
        reactor.state
            .map { $0.editButtonState }
            .asDriver(onErrorJustReturn: .more)
            .drive(self.wishDetailView.editButton.rx.state)
            .disposed(by: self.disposeBag)
    
        reactor.state
            .map { $0.memo }
            .distinctUntilChanged()
            .filter { $0 != "wrtie_placeholder_memo".localized && $0 != "detail_memo_empty".localized }
            .asDriver(onErrorJustReturn: "")
            .drive(self.wishDetailView.memoField.rx.setText)
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
        
        self.wishDetailView.scrollView.contentInset.bottom = keyboardViewEndFrame.height
        self.wishDetailView.scrollView.scrollIndicatorInsets = self.wishDetailView.scrollView.contentInset
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        self.wishDetailView.scrollView.contentInset.bottom = .zero
    }
}

extension WishDetailViewController: SharePhotoDelegate {
    
    func onSuccessSave() {
        self.wishDetailView.showFinishToast()
    }
}

extension WishDetailViewController: NotificationViewControllerDelegate {
    func onDeleteNotification(index: Int) {
        self.wishDetailReactor.action.onNext(.deleteNotification(index: index))
    }
    
    func onEditNotification(index: Int, notification: SeepNotification) {
        self.wishDetailReactor.action.onNext(
            .updateNotification(index: index, notification: notification)
        )
    }
    
    func onAddNotification(notification: SeepNotification) {
        self.wishDetailReactor.action.onNext(.addNotification(notification))
    }
}
