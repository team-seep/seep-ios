import UIKit

protocol WishDetailCoordinator: AnyObject, BaseCoordinator {
    func showMoreMenu(
        items: [DetailMoreMenu.Item],
        onSelect: @escaping (DetailMoreMenu.Item) -> Void
    )
    
    func presentSharePhoto(wish: Wish)
    
    func pushNotification(
        totalNotifications: [SeepNotification],
        selectedIndex: Int?
    )
    
    func pushEdit(wish: Wish)
}

extension WishDetailCoordinator where Self: WishDetailViewController {
    /// ⋯ 메뉴 (GH-59 R-9). 항목 구성은 `DetailMoreMenu`, 삭제·완료 취소는 여기서 한 번 더 묻는다.
    func showMoreMenu(
        items: [DetailMoreMenu.Item],
        onSelect: @escaping (DetailMoreMenu.Item) -> Void
    ) {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        items.forEach { item in
            let action = UIAlertAction(
                title: item.title,
                style: item.isDestructive ? .destructive : .default
            ) { [weak self] _ in
                switch item {
                case .delete:
                    self?.showDeleteAlert { onSelect(item) }
                case .cancelFinish:
                    self?.showCancelFinishAlert { onSelect(item) }
                case .addCalendar, .share, .deletePhoto:
                    onSelect(item)
                }
            }
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: Strings.detailActionSheetCancel, style: .cancel))
        
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
          message: Strings.detailDeleteMessage
        ) {
            onTapDelete()
        }
    }
    
    private func showCancelFinishAlert(onTapCancelFinish: @escaping () -> Void) {
        AlertUtils.showWithCancel(
            viewController: self,
            title: Strings.detailCancelFinishTitle,
            message: Strings.detailCancelFinishDescription,
            okButton: Strings.detailCancelFinishOk,
            cancelButton: Strings.detailCancelFinishNo
        ) {
            onTapCancelFinish()
        }
    }
}
