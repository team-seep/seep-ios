import UIKit

/// 싶 적기 컨트롤·단축어(`OpenWriteIntent`)가 만든 링크를 홈에 넘긴다 (GH-49 R-4, R-5, R-11)
/// 위젯 URL 과 같은 `Preference.reservedDeepLink` 에 남기고, 홈이 떠 있으면 바로 처리시킨다.
/// 스플래시 중(냉시작)이면 남겨만 두고 홈 첫 로드가 처리한다.
final class WriteDeepLinkOpener: WriteDeepLinkOpening, @unchecked Sendable {
    private let preference: Preference
    private let homeProvider: @MainActor () -> HomeViewController?

    init(
        preference: Preference = .shared,
        homeProvider: @escaping @MainActor () -> HomeViewController? = WriteDeepLinkOpener.currentHome
    ) {
        self.preference = preference
        self.homeProvider = homeProvider
    }

    @MainActor
    func open(_ deepLink: WidgetDeepLink) async {
        guard let url = deepLink.url else { return }
        preference.reservedDeepLink = url.absoluteString
        // 위젯 URL 과 달리 홈 위에 다른 화면이 있어도 처리한다. 작성 화면은 맨 위 화면 위에 뜬다 (R-5, R-12)
        homeProvider()?.handleReservedDeepLink()
    }

    @MainActor
    private static func currentHome() -> HomeViewController? {
        let navigationViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0.delegate as? SceneDelegate)?.window?.rootViewController as? UINavigationController }
            .first
        return navigationViewController?.viewControllers.first as? HomeViewController
    }
}
