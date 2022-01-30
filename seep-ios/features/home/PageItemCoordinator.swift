protocol PageItemCoordinator: AnyObject, BaseCoordinator {
    func presentWishDetail(wish: Wish)
}

extension PageItemCoordinator {
    func presentWishDetail(wish: Wish) {
        let viewController = WishDetailViewController.instance(wish: wish, mode: .fromHome)
        
        viewController.delegate = self as? WishDetailDelegate
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
}
