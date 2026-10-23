import Foundation

/// 싶 적기 컨트롤·단축어(`OpenWriteIntent`)가 만든 링크를 앱 라우터에 넘긴다 (GH-49 R-4, R-5, R-11).
/// 메인이 뜨기 전(냉시작)이면 `Preference.reservedDeepLink`에 남겨 두고 메인이 뜰 때 처리한다.
/// 위젯 URL 과 달리 다른 화면이 떠 있어도 작성 화면을 맨 위에 띄운다 (GH-64 `AppRouter.openFromIntent`)
final class WriteDeepLinkOpener: WriteDeepLinkOpening, @unchecked Sendable {
    private let routerProvider: @MainActor () -> AppRouter
    private let logManager: LogManagerProtocol

    init(
        routerProvider: @escaping @MainActor () -> AppRouter = { AppEnvironment.shared.router },
        logManager: LogManagerProtocol = LogManager.shared
    ) {
        self.routerProvider = routerProvider
        self.logManager = logManager
    }

    @MainActor
    func open(_ deepLink: WidgetDeepLink) async {
        guard let handled = routerProvider().openFromIntent(deepLink),
              let event = handled.writeIntentClickEvent else { return }
        // 컨트롤·단축어로 열었으면 클릭 로그를 남긴다 (GH-49 TC-12, TC-13)
        logManager.sendEvent(event: event)
    }
}
