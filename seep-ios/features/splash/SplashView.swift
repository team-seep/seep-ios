import UIKit
import Lottie

class SplashView: BaseView {
  
  let lottieView = AnimationView().then {
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
    
  func playRandomSplash(completion: @escaping ((Bool) -> Void)) {
    let randomInteger = Int.random(in: 1..<4)
    
    self.lottieView.animation = Animation.named("splash\(randomInteger)")
    self.lottieView.play(completion: completion)
  }
}
