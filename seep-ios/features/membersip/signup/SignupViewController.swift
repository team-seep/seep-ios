import Foundation

final class SignupViewController: BaseVC {
    private let signupView = SignupView()
    
    static func instance() -> SignupViewController {
        return SignupViewController(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = self.signupView
    }
}
