import UIKit

protocol WishDetailCoordinator: AnyObject, BaseCoordinator {
    func showActionSheet(
        mode: DetailMode,
        onTapShare: @escaping () -> Void,
        onTapDelete: @escaping () -> Void,
        onTapCancelFinish: @escaping () -> Void
    )
    
    func presentSharePhoto(wish: Wish)
}

extension WishDetailCoordinator where Self: WishDetailViewController {
    func showActionSheet(
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
          
          alertController.addAction(deleteAction)
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
