protocol PageItemCoordinator: AnyObject, BaseCoordinator {
    func presentWishDetail(wish: Wish)
}

extension PageItemCoordinator {
    func presentWishDetail(wish: Wish) {
        let viewController = DetailVC.instance(wish: wish, mode: .fromHome)
        
        viewController.delegate = self as? DetailDelegate
        self.presenter.present(viewController, animated: true, completion: nil)
    }
}
