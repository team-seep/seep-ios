import UserNotifications

import RxSwift

protocol NotificationManagerProtocol {
    func reserveNotifications(wish: Wish)
    
    func cancelNotifications(wish: Wish)
}

final class NotificationManager: NotificationManagerProtocol {
    static let shared = NotificationManager()
    
    func reserveNotifications(wish: Wish) {
        guard let deadline = wish.endDate else { return }
        for notification in wish.notifications {
            self.reserveNotification(
                title: wish.title,
                deadline: deadline,
                notification: notification
            )
        }
    }
    
    func cancelNotifications(wish: Wish) {
        for notification in wish.notifications {
            self.cancelNotification(notification: notification)
        }
    }
    
    private func reserveNotification(
        title: String,
        deadline: Date,
        notification: SeepNotification
    ) {
        let notificationContent = UNMutableNotificationContent().then {
            $0.title = "notification_title".localized
            $0.body = String(format: "notification_body_format".localized, title)
            $0.sound = .default
        }
        var trigger: UNCalendarNotificationTrigger
        
        switch notification.type {
        case .targetDay:
            let date = notification.time.setDay(date: deadline)
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .dayAgo:
            let date = notification.time
                .setDay(date: deadline)
                .addDay(day: 1)
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .twoDayAgo:
            let date = notification.time
                .setDay(date: deadline)
                .addDay(day: 2)
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .weekAgo:
            let date = notification.time
                .setDay(date: deadline)
                .addDay(day: -7)
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .everyDay:
            let date = notification.time
                .setDay(date: deadline)
            let components = Calendar.current.dateComponents(
                [.hour, .minute, .second],
                from: date
            )
            
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: notification.id,
            content: notificationContent,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    private func cancelNotification(notification: SeepNotification) {
        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(withIdentifiers: [notification.id])
    }
}
