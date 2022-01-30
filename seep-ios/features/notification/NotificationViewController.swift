import UIKit

import ReactorKit

protocol NotificationViewControllerDelegate: AnyObject {
    func onEditNotification(index: Int, notification: SeepNotification)
    
    func onAddNotification(notification: SeepNotification)
    
    func onDeleteNotification(index: Int)
}

final class NotificationViewController: BaseVC, View, NotificationCoordinator {
    weak var delegate: NotificationViewControllerDelegate?
    private let notificationView = NotificationView()
    private let notificationReactor: NotificationReactor
    private weak var coordinator: NotificationCoordinator?
    
    private let datePicker = UIDatePicker().then {
        $0.datePickerMode = .time
        $0.preferredDatePickerStyle = .wheels
        $0.locale = .init(identifier: "ko_KO")
    }
    
    init(
        totalNotifications: [SeepNotification],
        selectedIndex: Int? = nil
    ) {
        self.notificationReactor = NotificationReactor(
            totalNotifications: totalNotifications,
            selectedIndex: selectedIndex
        )
        
        super.init(nibName: nil, bundle: nil)
        if let selectedIndex = selectedIndex {
            self.notificationView.bind(notification: totalNotifications[selectedIndex])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func instance(
        totalNotifications: [SeepNotification],
        selectedIndex: Int? = nil
    ) -> NotificationViewController {
        return NotificationViewController(
            totalNotifications: totalNotifications,
            selectedIndex: selectedIndex
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func loadView() {
        self.view = self.notificationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coordinator = self
        self.reactor = self.notificationReactor
        self.notificationView.timeField.inputView = self.datePicker
    }
    
    override func bindEvent() {
        self.notificationView.backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.notificationView.accessoryView.finishButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.notificationView.endEditing(true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.notificationReactor.addNotificationPublisher
            .asDriver(onErrorJustReturn: SeepNotification())
            .drive(onNext: { [weak self] notification in
                self?.delegate?.onAddNotification(notification: notification)
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.notificationReactor.editNotificationPublisher
            .asDriver(onErrorJustReturn: (SeepNotification(), 0))
            .drive(onNext: { [weak self] (notification, selectedIndex) in
                self?.delegate?.onEditNotification(index: selectedIndex, notification: notification)
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.notificationReactor.deleteNotificationPublisher
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] deletedIndex in
                self?.delegate?.onDeleteNotification(index: deletedIndex)
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.notificationReactor.showToastPublisher
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] message in
                self?.coordinator?.showToast(message: message)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: NotificationReactor) {
        // Bind Action
        self.notificationView.deleteButton.rx.tap
            .map { Reactor.Action.tapDeleteButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.notificationView.notificationGroupView.rx.selectedType
            .map { Reactor.Action.selectNotificationType($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.datePicker.rx.date
            .skip(1)
            .do(onNext: { [weak self] date in
                self?.notificationView.timeField.setTime(date: date)
            })
            .map { Reactor.Action.inputNotificationTime($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.notificationView.addButton.rx.tap
            .map { Reactor.Action.tapAddButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { !$0.isDeletable }
            .asDriver(onErrorJustReturn: false)
            .drive(self.notificationView.deleteButton.rx.isHidden)
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
        
        self.notificationView.scrollView.contentInset.bottom = keyboardViewEndFrame.height
        self.notificationView.scrollView.scrollIndicatorInsets = self.notificationView.scrollView.contentInset
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        self.notificationView.scrollView.contentInset.bottom = .zero
    }
}

extension NotificationViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.notificationView.hideWriteButton()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.notificationView.showWriteButton()
    }
}
