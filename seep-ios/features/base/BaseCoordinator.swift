import UIKit

protocol BaseCoordinator {
    var presenter: BaseViewController { get }
    
    func popup(animated: Bool)
    
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
    
    func showToast(message: String)
    
    func showErrorAlert(error: Error)
    
    func goToSignin()
}

extension BaseCoordinator where Self: BaseViewController {
    var presenter: BaseViewController {
        return self
    }
    
    func popup(animated: Bool = true) {
        self.presenter.navigationController?.popViewController(animated: animated)
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.presenter.dismiss(animated: true, completion: nil)
    }
    
    func showToast(message: String) {
        ToastManager.shared.show(message: message)
    }
    
    func showErrorAlert(error: Error) {
        if let httpError = error as? HTTPError,
           httpError == .unauthorized {
            AlertUtils.showWithAction(
                controller: self,
                title: nil,
                message: httpError.description
            ) {
                UserDefaultsUtils().clear()
                self.goToSignin()
            }
        } else if let localizedError = error as? LocalizedError {
            AlertUtils.show(
                viewController: self,
                title: nil,
                message: localizedError.errorDescription
            )
        } else {
            AlertUtils.show(
                viewController: self,
                title: nil,
                message: error.localizedDescription
            )
        }
    }
    
    func goToSignin() {
        if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
          delegate.goToSignin()
        }
    }
}
