import UIKit

protocol WishDetailCoordinator: AnyObject, BaseCoordinator {
    func showActionSheet(
        wish: Wish,
        mode: DetailMode,
        onTapShare: @escaping () -> Void,
        onTapDelete: @escaping () -> Void,
        onTapCancelFinish: @escaping () -> Void
    )
    
    func presentSharePhoto(wish: Wish)
    
    func pushNotification(
        totalNotifications: [SeepNotification],
        selectedIndex: Int?
    )
    
    func pushEdit(wish: Wish)
}

extension WishDetailCoordinator where Self: WishDetailViewController {
    func showActionSheet(
        wish: Wish,
        mode: DetailMode,
        onTapShare: @escaping () -> Void,
        onTapDelete: @escaping () -> Void,
        onTapCancelFinish: @escaping () -> Void
    ) {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        let cancelAction = UIAlertAction(
          title: "detail_action_sheet_cancel".localized,
          style: .cancel,
          handler: nil
        )
        let shereAction = UIAlertAction(
          title: "detail_action_sheet_share".localized,
          style: .default
        ) { action in
          onTapShare()
        }
        
        if mode == .fromHome {
            let deleteAction = UIAlertAction(
                title: "detail_action_sheet_delete".localized,
                style: .destructive
            ) { [weak self] action in
                self?.showDeleteAlert(onTapDelete: onTapDelete)
            }
            
            let editAction = UIAlertAction(
                title: "detail_action_sheet_edit".localized,
                style: .default
            ) { [weak self] action in
                self?.pushEdit(wish: wish)
            }
          
          alertController.addAction(deleteAction)
            alertController.addAction(editAction)
        } else {
          let cancelFinishAction = UIAlertAction(
            title: "detail_action_sheet_cancel_finish".localized,
            style: .default
          ) { [weak self] action in
            self?.showCancelFinishAlert(onTapCancelFinish: onTapCancelFinish)
          }
          
          alertController.addAction(cancelFinishAction)
        }
        
        alertController.addAction(shereAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentSharePhoto(wish: Wish) {
        let viewController = SharePhotoVC.instance(wish: wish)
        
        viewController.delegate = self
        self.present(viewController, animated: true, completion: nil)
    }
    
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
    
    func pushEdit(wish: Wish) {
        let viewController = WishEditViewController.instance(wish: wish)
        
        viewController.delegate = self
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showDeleteAlert(onTapDelete: @escaping () -> Void) {
        AlertUtils.showWithCancel(
          viewController: self,
          title: nil,
          message: "detail_delete_message".localized
        ) {
            onTapDelete()
        }
    }
    
    private func showCancelFinishAlert(onTapCancelFinish: @escaping () -> Void) {
        AlertUtils.showWithCancel(
            viewController: self,
            title: "detail_cancel_finish_title".localized,
            message: "detail_cancel_finish_description".localized,
            okButton: "detail_cancel_finish_ok".localized,
            cancelButton: "detail_cancel_finish_no".localized
        ) {
            onTapCancelFinish()
        }
    }
}
