import Foundation

/// 위젯은 GA 를 직접 보내지 못해, 위젯 링크로 앱이 열렸을 때 앱이 클릭 로그를 남긴다 (GH-47 트래킹 이벤트)
extension WidgetDeepLink.Source {
    var logObjectId: LogObjectId {
        switch self {
        case .lockscreenDday:
            return .lockscreenDdayWidget
        case .lockscreenRemain:
            return .lockscreenRemainWidget
        }
    }

    var clickEvent: ClickEvent {
        return ClickEvent(screen: .lockScreenWidget, objectType: .widget, objectId: logObjectId)
    }
}
