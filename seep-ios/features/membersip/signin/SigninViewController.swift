import UIKit

final class SigninViewController: BaseVC {
    private let signinView = SigninView()
    
    static func instance() -> SigninViewController {
        return SigninViewController(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = self.signinView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
