import Foundation

/// 앱 전체가 같이 쓰는 SwiftUI 기반 객체. `SeepApp`이 환경값으로 내려 주고,
/// SwiftUI 밖(앱 인텐트 `WriteDeepLinkOpener`)에서는 `shared`로 닿는다
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let router: AppRouter
    let toastCenter: ToastCenter
    let appLock: AppLockOverlayViewModel

    init(
        router: AppRouter? = nil,
        toastCenter: ToastCenter? = nil,
        appLock: AppLockOverlayViewModel? = nil
    ) {
        self.router = router ?? AppRouter()
        self.toastCenter = toastCenter ?? ToastCenter()
        self.appLock = appLock ?? AppLockOverlayViewModel()
    }
}
