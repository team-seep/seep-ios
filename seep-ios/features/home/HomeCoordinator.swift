import UIKit

protocol HomeCoordinator: AnyObject, BaseCoordinator {
    func presentWrite(category: Category)
    
    func pushFinish(category: Category)
}

extension HomeCoordinator {
    func presentWrite(category: Category) {
        let viewController = WriteViewController.instance(category: category)
        
        viewController.delegate = self as? WriteDelegate
        
        let navigationViewController = UINavigationController(rootViewController: viewController).then {
            $0.isNavigationBarHidden = true
            $0.modalPresentationStyle = .overCurrentContext
        }
        
        self.presenter.present(navigationViewController, animated: true, completion: nil)
    }
    
    func pushFinish(category: Category) {
        let viewController = FinishedVC.instance(category: category)
        
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
}
