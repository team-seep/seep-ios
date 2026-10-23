import Foundation

/// 체크 위젯은 GA 를 직접 보내지 못해, 위젯이 쌓아 둔 실행 기록을 앱이 클릭 로그로 보낸다 (GH-48 트래킹 이벤트)
extension WidgetCheckStore.Action {
    var logObjectId: LogObjectId {
        switch self {
        case .checkStep:
            return .widgetCheckStep
        case .finishWish:
            return .widgetFinishWish
        case .unfinishWish:
            return .widgetUnfinishWish
        }
    }

    var clickEvent: ClickEvent {
        return ClickEvent(screen: .checkWidget, objectType: .widget, objectId: logObjectId)
    }
}
