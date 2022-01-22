import UIKit

protocol WriteCoordinator: AnyObject, BaseCoordinator {
    func pushNotification()
}

extension WriteCoordinator {
    func pushNotification() {
        let viewController = NotificationViewController.instance()
        
        self.presenter.navigationController?.pushViewController(
            viewController,
            animated: true
        )
    }
}
