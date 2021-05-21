import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?


  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
    self.window?.windowScene = windowScene
    self.window?.rootViewController = SplashVC.instance()
    self.window?.makeKeyAndVisible()
  }
  
  func goToMain() {
    guard let window = self.window else { return }
    
    window.rootViewController = HomeVC.instance()
    UIView.transition(
      with: window,
      duration: 0.3,
      options: .transitionCrossDissolve
    ) { [weak window] in
      window?.makeKeyAndVisible()
    }
  }
}
