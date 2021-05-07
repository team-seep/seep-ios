import UserNotifications

class NotificationManager {
  
  static let shared = UNUserNotificationCenter.current()
  
  // Todo: 예약, 취소
  
  func reserve(wish: Wish) {
    self.reserveTwoDayBeforeNotification(wish: wish)
    self.reserveDayBeforeNotification(wish: wish)
  }
  
  private func reserveDayBeforeNotification(wish: Wish) {
    let notificationContent = UNMutableNotificationContent().then {
      $0.title = String(format: "notification_two_day_before_format".localized, wish.title)
    }
    let trigger = UNCalendarNotificationTrigger(
      dateMatching: Calendar.current.dateComponents([.year, .month, .day], from: wish.date),
      repeats: false
    )
    let request = UNNotificationRequest(
      identifier: wish._id.stringValue,
      content: notificationContent,
      trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      print(error)
    }
  }
  
  private func reserveTwoDayBeforeNotification(wish: Wish) {
    let notificationContent = UNMutableNotificationContent().then {
      $0.title = String(format: "notification_day_before_format".localized, wish.title)
    }
    let trigger = UNCalendarNotificationTrigger(
      dateMatching: Calendar.current.dateComponents([.year, .month, .day], from: wish.date),
      repeats: false
    )
    let request = UNNotificationRequest(
      identifier: wish._id.stringValue,
      content: notificationContent,
      trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      print(error)
    }
  }
}
