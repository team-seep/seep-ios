import UIKit

protocol WriteCoordinator: AnyObject, BaseCoordinator {
    func pushNotification(
        totalNotifications: [SeepNotification],
        selectedIndex: Int?
    )
}

extension WriteCoordinator {
    func pushNotification(
        totalNotifications: [SeepNotification],
        selectedIndex: Int?
    ) {
        let viewController = NotificationViewController.instance(
            totalNotifications: totalNotifications,
            selectedIndex: selectedIndex
        )
        
        viewController.delegate = self as? NotificationViewControllerDelegate
        self.presenter.navigationController?.pushViewController(
            viewController,
            animated: true
        )
    }
}
