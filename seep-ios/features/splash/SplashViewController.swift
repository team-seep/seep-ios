import UIKit

final class SplashViewController: BaseViewController {
    private let splashView = SplashView()
    
    static func instance() -> SplashViewController {
        return SplashViewController(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.splashView)
        self.splashView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        self.splashView.playRandomSplash { [weak self] isComplete in
            self?.goToHome()
        }
    }
    
    private func goToHome() {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.goToMain()
        }
    }
}
