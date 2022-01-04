import UserNotifications
import RxSwift

class NotificationManager {
    
    static let shared = NotificationManager()
    
    final let twoDay = 60 * 60 * 24 * 2
    final let oneDay = 60 * 60 * 24
    
    func reserve(wish: Wish) {
        let distance = Date().distance(to: wish.date.startOfDay)
        
        if distance >= TimeInterval(twoDay) {
            self.reserveTwoDayBeforeNotification(wish: wish)
        }
        if distance >= TimeInterval(oneDay) {
            self.reserveDayBeforeNotification(wish: wish)
        }
    }
    
    func cancel(wish: Wish) {
        let ids = [wish._id.stringValue + "_day_before", wish._id.stringValue + "_two_day_before"]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    private func reserveDayBeforeNotification(wish: Wish) {
        let notificationContent = UNMutableNotificationContent().then {
            $0.title = "notification_day_before_title".localized
            $0.body = String(format: "notification_day_before_\(wish.category)_body_foramt".localized, wish.title)
            $0.sound = .default
        }
        
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: wish.date)
        components.hour = 11
        components.minute = 0
        components.second = 0
        components.day = (components.day ?? 0) - 1
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: wish._id.stringValue + "_day_before",
            content: notificationContent,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    private func reserveTwoDayBeforeNotification(wish: Wish) {
        let notificationContent = UNMutableNotificationContent().then {
            $0.title = "notification_two_day_before_title".localized
            $0.body = String(format: "notification_two_day_before_\(wish.category)_body_format".localized, wish.title)
            $0.sound = .default
        }
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: wish.date)
        components.hour = 11
        components.minute = 0
        components.second = 0
        components.day = (components.day ?? 0) - 2
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: wish._id.stringValue + "_tow_day_before",
            content: notificationContent,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}
