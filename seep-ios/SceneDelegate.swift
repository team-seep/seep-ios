import UIKit
import WidgetKit

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
        
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        window.rootViewController = navigationController
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
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 위젯 링크는 Preference 에 남겨 홈이 처리한다. 냉시작이면 홈 첫 로드에서, 홈이 이미 떠 있으면 바로 (GH-50 R-1, R-2)
    private func handleDeepLink(urlContexts: Set<UIOpenURLContext>) {
        guard let widgetDeepLink = urlContexts.first(where: { $0.url.scheme == "widget" }) else { return }
        
        Preference.shared.reservedDeepLink = widgetDeepLink.url.absoluteString
        
        if let navigationViewController = self.window?.rootViewController as? UINavigationController,
           let homeViewController = navigationViewController.topViewController as? HomeViewController {
            homeViewController.handleReservedDeepLink()
        }
    }
}
