import UIKit

protocol SigninCoordinator: BaseCoordinator, AnyObject {
    func pushSignup()
    
    func goToMain()
}

extension SigninCoordinator {
    func pushSignup() {
        let viewController = SignupViewController.instance()
        
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func goToMain() {
        if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
          delegate.goToMain()
        }
    }
}
