import Foundation
import UIKit

import RxSwift
import ReactorKit

protocol WishEditViewControllerDelegate: AnyObject {
    func onUpdateWish(wish: Wish)
}

final class WishEditViewController: BaseVC, View, WishEditCoordinator {
    weak var delegate: WishEditViewControllerDelegate?
    private let wishEditView = WishEditView()
    private let wishEditReactor: WishEditReactor
    private weak var coordinator: WishEditCoordinator?
    private var isKeyboardShown = false
    
    private let datePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.locale = .init(identifier: "ko_KO")
    }
    
    init(wish: Wish) {
        self.wishEditReactor = WishEditReactor(
            wish: wish,
            wishService: WishService(),
            notificationManager: NotificationManager.shared
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func instance(wish: Wish) -> WishEditViewController {
        return WishEditViewController(wish: wish)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func loadView() {
        self.view = self.wishEditView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.wishEditReactor
        self.coordinator = self
        self.setupKeyboardNotification()
        self.wishEditView.dateField.inputView = self.datePicker
        
        self.wishEditView.memoField.setEditableText(text: self.wishEditReactor.initialState.memo)
    }
    
    override func bindEvent() {
        self.wishEditView.backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishEditView.tapBackground.rx.event
            .asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.wishEditView.endEditing(true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishEditView.accessoryView.finishButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.wishEditView.endEditing(true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishEditReactor.pushNotificationPublisher
            .asDriver(onErrorJustReturn: ([], nil))
            .drive(onNext: { [weak self] (notifications, selectedIndex) in
                self?.coordinator?.pushNotification(
                    totalNotifications: notifications,
                    selectedIndex: selectedIndex
                )
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishEditReactor.popupWithWishPublisher
            .asDriver(onErrorJustReturn: Wish())
            .drive(onNext: { [weak self] wish in
                self?.delegate?.onUpdateWish(wish: wish)
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.wishEditReactor.showToastPublisher
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] message in
                self?.coordinator?.showToast(message: message)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: WishEditReactor) {
        // MARK: Action
        self.wishEditView.emojiInputView.rx.emoji
            .map { Reactor.Action.inputEmoji($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.categoryView.rx.tapCategory
            .map { Reactor.Action.tapCategory($0) }
            .do(onNext: { _ in
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
                
        self.wishEditView.titleField.rx.text.orEmpty
            .skip(1)
            .map { Reactor.Action.inputTitle($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.dateSwitch.rx.value
            .skip(1)
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
                
                self?.wishEditView.dateField.textField.text = dateString
            })
            .map { Reactor.Action.inputDeadline($0.endOfDay) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.notificationSwitch.rx.value
            .skip(1)
            .map { Reactor.Action.tapNotificationSwitch($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.addNotificationButton.rx.tap
            .map { Reactor.Action.tapAddNotificationButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.memoField.rx.text.orEmpty
            .skip(1)
            .filter { $0 != "wrtie_placeholder_memo".localized }
            .map { Reactor.Action.inputMemo($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.hashtagCollectionView.rx.itemSelected
            .map { Reactor.Action.tapHashtag(index: $0.row) }
            .do(onNext: { [weak self] _ in
                self?.wishEditView.endEditing(true)
            })
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.hashtagField.rx.text.orEmpty
            .skip(1)
            .distinctUntilChanged()
            .do(onNext: { [weak self] text in
                if !text.isEmpty {
                    self?.wishEditView.hashtagCollectionView.deselectAllItems(animated: true)
                }
            })
            .map { Reactor.Action.inputHashtag($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.wishEditView.editButton.rx.tap
            .map { Reactor.Action.tapEditButton }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // MARK: State
        reactor.state
            .map { $0.emoji }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] emoji in
                self?.wishEditView.emojiInputView.setEmoji(emoji: emoji)
            })
            .disposed(by: self.eventDisposeBag)
        
        reactor.state
            .map { $0.category }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .wantToDo)
            .drive(onNext: { [weak self] category in
                self?.wishEditView.setTitlePlaceholder(by: category)
                self?.wishEditView.categoryView.moveActiveButton(category: category)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.title }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] title in
                self?.wishEditView.titleField.setText(text: title)
            })
            .disposed(by: self.disposeBag)
                
        reactor.state
            .map { $0.titleError }
            .distinctUntilChanged()
            .skip(1)
            .asDriver(onErrorJustReturn: nil)
            .drive(self.wishEditView.titleField.rx.errorMessage)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.deadline }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] date in
                self?.datePicker.date = date ?? Date()
                self?.wishEditView.dateField.setDate(date: date)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.deadlineError }
            .distinctUntilChanged()
            .skip(1)
            .asDriver(onErrorJustReturn: nil)
            .drive(self.wishEditView.dateField.rx.errorMessage)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isDeadlineEnable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.wishEditView.dateSwitch.rx.isOn)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isDeadlineEnable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.wishEditView.dateField.rx.isDateEnable)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { state in
                return state.notifications.map { ($0, state.isNotificationEnable) }
            }
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { [weak self] (notificationsWithEnable) in
                self?.wishEditView.updateNotificationTableViewHeight(by: notificationsWithEnable)
            })
            .drive(self.wishEditView.notificationTableView.rx.items(
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
            .asDriver(onErrorJustReturn: false)
            .drive(self.wishEditView.rx.isNotificationEnable)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.hashtags }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(self.wishEditView.hashtagCollectionView.rx.items(
                    cellIdentifier: HashtagCollectionViewCell.registerID,
                    cellType: HashtagCollectionViewCell.self
            )) { row, hashtag, cell in
                cell.bind(type: hashtag)
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .compactMap { $0.selectedHashtag }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .trip)
            .drive(onNext: { [weak self] selectedHashtag in
                self?.wishEditView.selectHashtag(hashtag: selectedHashtag)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.customHashtag }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(self.wishEditView.hashtagField.rx.setText)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.editButtonState }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .more)
            .drive(self.wishEditView.editButton.rx.state)
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
        
        self.wishEditView.scrollView.contentInset.bottom = keyboardViewEndFrame.height
        self.wishEditView.scrollView.scrollIndicatorInsets = self.wishEditView.scrollView.contentInset
        self.isKeyboardShown = true
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        self.wishEditView.scrollView.contentInset.bottom = .zero
        self.isKeyboardShown = false
    }
}

extension WishEditViewController: NotificationViewControllerDelegate {
    func onDeleteNotification(index: Int) {
        self.wishEditReactor.action.onNext(.deleteNotification(index: index))
    }
    
    func onEditNotification(index: Int, notification: SeepNotification) {
        self.wishEditReactor.action.onNext(
            .updateNotification(index: index, notification: notification)
        )
    }
    
    func onAddNotification(notification: SeepNotification) {
        self.wishEditReactor.action.onNext(.addNotification(notification))
    }
}
