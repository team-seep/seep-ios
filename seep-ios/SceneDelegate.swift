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
    
    self.handleDeepLink(urlContexts: connectionOptions.urlContexts)
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
  
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    self.handleDeepLink(urlContexts: URLContexts)
  }
  
  private func handleDeepLink(urlContexts: Set<UIOpenURLContext>) {
    guard let widgetDeepLink = urlContexts.first(where: { $0.url.scheme == "widget" }),
    let urlComponents = URLComponents(string: widgetDeepLink.url.absoluteString) else { return }
    
    if urlComponents.host == "add" {
      if let categoryQuery = urlComponents.queryItems?.first(where: { $0.name == "category" }),
         let category = Category(rawValue: categoryQuery.value ?? "") {
        
        if let navigationVC = self.window?.rootViewController as? UINavigationController,
           let homeVC = navigationVC.topViewController as? HomeVC {
          homeVC.showWirteVC(category: category)
        } else {
          UserDefaultsUtils().setDeepLink(deepLink: widgetDeepLink.url.absoluteString)
        }
      }
    }
  }
}
