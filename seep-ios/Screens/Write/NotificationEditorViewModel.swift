import Foundation
import Observation

/// 알림 추가·수정 시트를 여는 값. 이미 있는 알림 목록과 수정할 알림 위치(추가면 nil)
struct NotificationEditorConfig: Equatable {
    let notifications: [SeepNotification]
    let selectedIndex: Int?
}

extension NotificationEditorViewModel {
    enum Action: Equatable {
        case selectType(SeepNotification.NotificationType)
        case inputTime(Date)
        case tapSave
        case tapDelete
        case routeHandled
    }

    enum Route: Equatable {
        case saved(SeepNotification, index: Int?)
        case deleted(index: Int)
        case toast(String)
    }

    struct State: Equatable {
        var notification: SeepNotification
        /// 알림이 하나뿐인 첫 줄은 지울 수 없다 (레거시 `NotificationReactor`)
        let isDeletable: Bool
        let isEditing: Bool
    }
}

/// 알림 날짜(당일·1일 전·2일 전·일주일 전·매일)와 시간을 고르는 시트 (GH-64 R-41).
/// 저장 형식·중복 판정은 레거시 `NotificationReactor`와 같다 — 같은 종류·시각이 이미 있으면 저장하지 않는다 (TC-1303)
@Observable
final class NotificationEditorViewModel {
    static let types: [SeepNotification.NotificationType] = [.targetDay, .dayAgo, .twoDayAgo, .weekAgo, .everyDay]

    private(set) var state: State
    private(set) var route: Route?

    private let config: NotificationEditorConfig

    init(config: NotificationEditorConfig) {
        self.config = config
        if let index = config.selectedIndex, config.notifications.indices.contains(index) {
            state = State(
                notification: config.notifications[index],
                isDeletable: config.notifications.count != 1 || index != 0,
                isEditing: true
            )
        } else {
            state = State(notification: SeepNotification(), isDeletable: false, isEditing: false)
        }
    }

    func send(_ action: Action) {
        switch action {
        case .selectType(let type):
            state.notification.type = type
        case .inputTime(let time):
            state.notification.time = time
        case .tapSave:
            // 수정 중인 자기 자신과 같은 값으로 저장하는 것도 레거시처럼 중복으로 본다
            if config.notifications.contains(state.notification) {
                route = .toast(Strings.NotificationEditor.duplicate)
            } else {
                route = .saved(state.notification, index: config.selectedIndex)
            }
        case .tapDelete:
            guard state.isDeletable, let index = config.selectedIndex else { return }
            route = .deleted(index: index)
        case .routeHandled:
            route = nil
        }
    }
}
