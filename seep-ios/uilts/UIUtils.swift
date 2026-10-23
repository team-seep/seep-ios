import UIKit

public struct UIUtils {
    // Deprecated (GH-9): 창이 아니라 첫 scene의 화면 크기다. 새 코드는 뷰·컬렉션뷰의 bounds를 쓴다(린트 no_screen_size).
    public static var windowBounds: CGRect {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return .zero }
        
        return window.screen.bounds
    }
    
    public static var bottomSafeAreaInset: CGFloat {
        let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return window?.keyWindow?.safeAreaInsets.bottom ?? .zero
    }
    
    public static func getTopViewController(_ viewController: UIViewController) -> UIViewController {
        var presentingViewController = viewController
        while let presentedViewController = presentingViewController.presentedViewController {
            presentingViewController = presentedViewController
        }
        return presentingViewController
    }
}
