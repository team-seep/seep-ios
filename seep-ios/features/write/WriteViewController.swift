import Foundation
import UIKit

import RxSwift
import ReactorKit

protocol WriteDelegate: AnyObject {
    func onSuccessWrite(category: Category)
}

final class WriteViewController: BaseVC, View, WriteCoordinator {
    weak var delegate: WriteDelegate?
    private let writeView = WriteView()
    private let writeReactor: WriteReactor
    private weak var coordinator: WriteCoordinator?
    
    private let datePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.locale = .init(identifier: "ko_KO")
    }
    
    init(category: Category) {
        self.writeReactor = WriteReactor(
            category: category,
            wishService: WishService(),
            userDefaults: UserDefaultsUtils()
        )
        
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
        self.view = self.writeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.writeReactor
        self.coordinator = self
        self.setupKeyboardNotification()
        self.writeView.dateField.inputView = self.datePicker
        self.writeView.categoryView.moveActiveButton(category: self.writeReactor.currentState.category)
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
            .bind(to: self.writeReactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.hashtagField.rx.text.orEmpty
            .map { Reactor.Action.inputHashtag($0) }
            .bind(to: self.writeReactor.action)
            .disposed(by: self.disposeBag)
        
        self.writeView.writeButton.rx.tap
            .map { Reactor.Action.tapWriteButton }
            .bind(to: self.writeReactor.action)
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
            .asDriver(onErrorJustReturn: nil)
            .drive(self.writeView.titleField.rx.errorMessage)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.deadlineError }
            .asDriver(onErrorJustReturn: nil)
            .drive(self.writeView.dateField.rx.errorMessage)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.deadlineEnable }
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
        
        self.writeReactor.state
            .map { $0.writeButtonState }
            .observeOn(MainScheduler.instance)
            .bind(to: self.writeView.writeButton.rx.state)
            .disposed(by: self.disposeBag)
        
        //    self.writeReactor.state
        //      .map { $0.shouldDismiss }
        //      .distinctUntilChanged()
        //      .observeOn(MainScheduler.instance)
        //      .bind(onNext: { [weak self] shouldDismiss in
        //        guard let self = self else { return }
        //        if shouldDismiss {
        //          self.delegate?.onSuccessWrite(category: self.writeReactor.currentState.category)
        //          self.dismiss()
        //        }
        //      })
        //      .disposed(by: disposeBag)
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
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        self.writeView.scrollView.contentInset.bottom = .zero
    }
}

// TODO: 에러 디자인 나오면 적용
//extension WriteVC: UITextFieldDelegate {
//
//  func textField(
//    _ textField: UITextField,
//    shouldChangeCharactersIn range: NSRange,
//    replacementString string: String
//  ) -> Bool {
//    guard let text = textField.text else { return true }
//    let newLength = text.count + string.count - range.length
//
//    if newLength >= 18 {
//      self.writeView.titleField.rx.errorMessage.onNext("write_error_max_length_title".localized)
//    } else {
//      self.writeView.titleField.rx.errorMessage.onNext(nil)
//    }
//
//    return newLength <= 18
//  }
//}

extension WriteViewController: NotificationViewControllerDelegate {
    func onEditNotification(index: Int, notification: SeepNotification) {
        self.writeReactor.action.onNext(
            .updateNotification(index: index, notification: notification)
        )
    }
    
    func onAddNotification(notification: SeepNotification) {
        self.writeReactor.action.onNext(.addNotification(notification))
    }
}
