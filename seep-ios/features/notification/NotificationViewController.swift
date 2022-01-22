import UIKit

final class NotificationViewController: BaseVC, NotificationCoordinator {
    private let notificationView = NotificationView()
    private weak var coordinator: NotificationCoordinator?
    
    static func instance() -> NotificationViewController {
        return NotificationViewController(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = self.notificationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coordinator = self
    }
    
    override func bindEvent() {
        self.notificationView.backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.coordinator?.popup(animated: true)
            })
            .disposed(by: self.eventDisposeBag)
    }
}
