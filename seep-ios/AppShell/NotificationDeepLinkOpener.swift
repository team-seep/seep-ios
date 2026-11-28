import Foundation

/// 로컬 알림을 누르면 알림에 담긴 위시 상세 링크로 화면을 옮긴다 (GH-121 R-6, TC-10).
/// 메인이 뜨기 전(냉시작)이면 라우터가 링크를 맡아 두었다가 메인이 뜰 때 열고, 그때 `RootView`가 클릭 로그를 보낸다
@MainActor
struct NotificationDeepLinkOpener {
    private let router: AppRouter
    private let logManager: LogManagerProtocol

    init(router: AppRouter = AppEnvironment.shared.router, logManager: LogManagerProtocol = LogManager.shared) {
        self.router = router
        self.logManager = logManager
    }

    /// - Returns: 지금 화면을 옮겼으면 그 링크
    @discardableResult
    func open(userInfo: [AnyHashable: Any]) -> WidgetDeepLink? {
        guard let string = userInfo[SavingPlanNotification.deepLinkKey] as? String,
              let url = URL(string: string),
              let deepLink = router.openFromNotification(url: url) else { return nil }
        if let event = deepLink.source?.clickEvent {
            logManager.sendEvent(event: event)
        }
        return deepLink
    }
}
