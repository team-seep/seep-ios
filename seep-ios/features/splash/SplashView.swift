import UIKit
import Lottie

class SplashView: BaseView {
  
  let lottieView = AnimationView().then {
    $0.animation = Animation.named("splash")
    $0.contentMode = .scaleAspectFit
  }
  
  
  override func setup() {
    self.backgroundColor = .tennisGreen
    self.addSubview(lottieView)
  }
  
  override func bindConstraints() {
    self.lottieView.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
}
