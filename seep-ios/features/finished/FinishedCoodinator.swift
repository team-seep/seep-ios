protocol FinishedCoordinator: AnyObject, BaseCoordinator {
    func pushWishDetail(wish: Wish)
}

extension FinishedCoordinator {
    func pushWishDetail(wish: Wish) {
        let viewController = WishDetailViewController.instance(wish: wish, mode: .fromFinish)
        
        viewController.delegate = self as? WishDetailDelegate
        
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
}
