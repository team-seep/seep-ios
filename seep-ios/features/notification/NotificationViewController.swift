import UIKit

final class NotificationViewController: BaseVC, NotificationCoordinator {
    private let notificationView = NotificationView()
    private weak var coordinator: NotificationCoordinator?
    
    private let datePicker = UIDatePicker().then {
        $0.datePickerMode = .time
        $0.preferredDatePickerStyle = .wheels
        $0.locale = .init(identifier: "ko_KO")
    }
    
    static func instance() -> NotificationViewController {
        return NotificationViewController(nibName: nil, bundle: nil)
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
