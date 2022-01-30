import Foundation

import ReactorKit
import RxCocoa

final class NotificationReactor: Reactor {
    enum Action {
        case tapDeleteButton
        case selectNotificationType(SeepNotification.NotificationType)
        case inputNotificationTime(Date)
        case tapAddButton
    }
    
    enum Mutation {
        case deleteNotification(index: Int?)
        case setNotificationType(SeepNotification.NotificationType)
        case setNotificationTime(Date)
        case showToast(String)
        case addNotification(SeepNotification)
        case editNotification((SeepNotification, Int))
    }
    
    struct State {
        var notification: SeepNotification = SeepNotification()
        var isDeletable: Bool
    }
    
    let addNotificationPublisher = PublishRelay<SeepNotification>()
    let editNotificationPublisher = PublishRelay<(SeepNotification, Int)>()
    let deleteNotificationPublisher = PublishRelay<Int>()
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
            self.initialState = State(
                notification: totalNotifications[selectedIndex],
                isDeletable: totalNotifications.count != 1 || selectedIndex != 0
            )
        } else {
            self.initialState = State(isDeletable: false)
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .tapDeleteButton:
            return .just(.deleteNotification(index: self.selectedIndex))
            
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
        var newState = state
        
        switch mutation {
        case .deleteNotification(let index):
            guard let deleteIndex = index else { return newState }
            self.deleteNotificationPublisher.accept(deleteIndex)
            
        case .setNotificationType(let type):
            newState.notification.type = type
            
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
