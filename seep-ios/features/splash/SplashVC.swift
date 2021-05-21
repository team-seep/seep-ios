import UIKit

class SplashVC: BaseVC {
  
  private let splashView = SplashView()
  
  
  static func instance() -> SplashVC {
    return SplashVC(nibName: nil, bundle: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.splashView.lottieView.play { [weak self] isComplete in
      self?.goToHome()
    }
  }
  
  override func setupView() {
    self.view.addSubview(self.splashView)
    self.splashView.snp.makeConstraints { make in
      make.edges.equalTo(0)
    }
  }
  
  private func goToHome() {
    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
      sceneDelegate.goToMain()
    }
  }
}
