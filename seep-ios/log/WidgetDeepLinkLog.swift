import Foundation

/// 위젯은 GA 를 직접 보내지 못해, 위젯 링크로 앱이 열렸을 때 앱이 클릭 로그를 남긴다 (GH-47 트래킹 이벤트)
/// 체크 위젯(GH-48)의 위시 줄 열기는 트래킹 대상이 아니라 로그가 없다(체크 위젯은 실행 기록 로그만 보낸다)
extension WidgetDeepLink.Source {
    var logObjectId: LogObjectId? {
        switch self {
        case .lockscreenDday:
            return .lockscreenDdayWidget
        case .lockscreenRemain:
            return .lockscreenRemainWidget
        case .checkWidget, .control, .shortcut:
            // 체크 위젯 줄 열기는 트래킹 대상이 아니고, 컨트롤·단축어는 writeIntentClickEvent 가 보낸다 (GH-49)
            return nil
        }
    }

    var clickEvent: ClickEvent? {
        guard let logObjectId else { return nil }
        return ClickEvent(screen: .lockScreenWidget, objectType: .widget, objectId: logObjectId)
    }
}
