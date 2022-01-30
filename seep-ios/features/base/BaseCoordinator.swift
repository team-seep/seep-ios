import UIKit

protocol BaseCoordinator {
    var presenter: BaseVC { get }
    
    func popup(animated: Bool)
    
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
    
    func showToast(message: String)
}

extension BaseCoordinator where Self: BaseVC {
    var presenter: BaseVC {
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
}
