import Foundation

/// 근처 알림(`nearby-{wishId}`)을 누르면 그 위시 상세를 연다 (GH-126 R-8).
/// 위젯 링크와 같은 경로(`widget://wish?id=…&source=nearby_alert`)를 타서, 메인이 뜨기 전(냉시작)이면 맡아 뒀다가 메인이 뜰 때 연다.
/// 위시가 이뤄졌거나 지워졌으면 `AppRouter`가 홈을 연다
final class NearbyAlertOpener {
    private let routerProvider: @MainActor () -> AppRouter
    private let logManager: LogManagerProtocol

    init(
        routerProvider: @escaping @MainActor () -> AppRouter = { AppEnvironment.shared.router },
        logManager: LogManagerProtocol = LogManager.shared
    ) {
        self.routerProvider = routerProvider
        self.logManager = logManager
    }

    /// 근처 알림이면 열고 true, 다른 알림(D-day 등)이면 아무것도 하지 않고 false
    @MainActor
    @discardableResult
    func open(notificationIdentifier: String) -> Bool {
        guard let wishId = NearbyAlertRequest.wishId(fromIdentifier: notificationIdentifier),
              let url = WidgetDeepLink.wish(id: wishId, source: .nearbyAlert).url else { return false }
        logManager.sendEvent(event: CustomEvent(screen: .wishDetail, name: .openNearbyAlert))
        routerProvider().open(url: url)
        return true
    }
}
