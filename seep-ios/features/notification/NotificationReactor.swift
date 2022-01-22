import Foundation

import ReactorKit
import RxCocoa

final class NotificationReactor: Reactor {
    enum Action {
        case selectNotificationType(SeepNotification.NotificationType)
        case inputNotificationTime(Date)
        case tapAddButton
    }
    
    enum Mutation {
        case setNotificationType(SeepNotification.NotificationType)
        case setNotificationTime(Date)
        case showToast(String)
        case addNotification(SeepNotification)
        case editNotification((SeepNotification, Int))
    }
    
    struct State {
        var notification: SeepNotification = SeepNotification()
    }
    
    let addNotificationPublisher = PublishRelay<SeepNotification>()
    let editNotificationPublisher = PublishRelay<(SeepNotification, Int)>()
    let showToastPublisher = PublishRelay<String>()
    
    let initialState: State
    private let totalNotifications: [SeepNotification]
    private let selectedIndex: Int?
    
    init(
        totalNotifications: [SeepNotification],
        selectedIndex: Int?
    ) {
        self.totalNotifications = totalNotifications
        self.selectedIndex = selectedIndex
        if let selectedIndex = selectedIndex {
            self.initialState = State(notification: totalNotifications[selectedIndex])
        } else {
            self.initialState = State()
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectNotificationType(let type):
            return .just(.setNotificationType(type))
            
        case .inputNotificationTime(let time):
            return .just(.setNotificationTime(time))
            
        case .tapAddButton:
            if self.validateNotification(
                notification: self.currentState.notification,
                totalNotifications: self.totalNotifications
            ) {
                return .just(.showToast("🔕 이미 설정된 알림입니다."))
            } else {
                if let selectedIndex = self.selectedIndex {
                    return .just(.editNotification((self.currentState.notification, selectedIndex)))
                } else {
                    return.just(.addNotification(self.currentState.notification))
                }
            }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        let newState = state
        
        switch mutation {
        case .setNotificationType(let type):
            newState.notification.notificationType = type
            
        case .setNotificationTime(let time):
            newState.notification.time = time
            
        case .addNotification(let seepNotification):
            self.addNotificationPublisher.accept(seepNotification)
            
        case .editNotification(let notificationWithIndex):
            self.editNotificationPublisher.accept(notificationWithIndex)
            
        case .showToast(let message):
            self.showToastPublisher.accept(message)
        }
        
        return newState
    }
    
    private func validateNotification(
        notification: SeepNotification,
        totalNotifications: [SeepNotification]
    ) -> Bool {
        return totalNotifications.contains(notification)
    }
}
