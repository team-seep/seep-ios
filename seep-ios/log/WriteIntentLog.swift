import Foundation

/// 컨트롤·단축어는 GA 를 직접 보내지 못해, 링크로 작성 화면이 열릴 때 앱이 클릭 로그를 남긴다 (GH-49 트래킹 이벤트)
extension WidgetDeepLink {
    /// 싶 적기 컨트롤·단축어로 연 작성 화면 링크면 클릭 로그, 아니면(바로 적기 위젯 등) nil
    var writeIntentClickEvent: ClickEvent? {
        guard case .add(let category, let source) = self else { return nil }
        let objectId: LogObjectId
        switch source {
        case .control:
            objectId = .controlWrite
        case .shortcut:
            objectId = .shortcutWrite
        default:
            return nil
        }
        return ClickEvent(
            screen: .writeControl,
            objectType: .widget,
            objectId: objectId,
            extraParameters: [.category: category.rawValue]
        )
    }
}
