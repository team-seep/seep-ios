import UIKit
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    /// 앱 잠금 (GH-46). 잠금 화면은 별도 윈도우로 앱 전체를 덮는다
    private let appLockViewModel = AppLockViewModel()
    private var appLockWindow: AppLockWindow?
    
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
        self.appLockWindow = AppLockWindow(
            windowScene: windowScene,
            mainWindow: self.window,
            viewModel: self.appLockViewModel
        )

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
        // 콜드 스타트 잠금은 스플래시 다음, 홈이 뜨는 순간에 덮는다 (GH-46 R-5)
        appLockViewModel.input.didShowMain.send(())
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        self.handleDeepLink(urlContexts: URLContexts)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        WidgetCenter.shared.reloadAllTimelines()
        appLockViewModel.input.didEnterBackground.send(())
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        appLockViewModel.input.willResignActive.send(())
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        appLockViewModel.input.willEnterForeground.send(())
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        appLockViewModel.input.didBecomeActive.send(())
    }
    
    /// 위젯 링크는 Preference 에 남겨 홈이 처리한다. 냉시작이면 홈 첫 로드에서, 홈이 이미 떠 있으면 바로 (GH-50 R-1, R-2)
    private func handleDeepLink(urlContexts: Set<UIOpenURLContext>) {
        guard let widgetDeepLink = urlContexts.first(where: { $0.url.scheme == "widget" }) else { return }
        
        guard let navigationViewController = self.window?.rootViewController as? UINavigationController else {
            // 스플래시 중(냉시작): 홈 첫 로드가 처리한다
            Preference.shared.reservedDeepLink = widgetDeepLink.url.absoluteString
            return
        }
        // 홈 위에 다른 화면이 있으면 링크를 남기지 않는다. 남기면 다음 실행 때 엉뚱하게 작성 화면이 열린다
        guard let homeViewController = navigationViewController.topViewController as? HomeViewController,
              homeViewController.presentedViewController == nil else { return }
        
        Preference.shared.reservedDeepLink = widgetDeepLink.url.absoluteString
        homeViewController.handleReservedDeepLink()
    }
}
