import os
import UserNotifications


protocol NotificationManagerProtocol {
    /// D-day 알림과, 켜 둔 위시면 근처 알림(GH-126)도 예약한다
    func reserveNotifications(wish: Wish)

    /// 위시의 D-day 알림과 근처 알림(GH-126)을 모두 지운다. 완료·삭제 어느 경로로 불러도 근처 알림이 남지 않는다 (R-7)
    func cancelNotifications(wish: Wish)

    /// 시스템 알림 권한. 설정 탭 "D-day 알림" 줄에 보여준다 (GH-64 R-25)
    func authorizationStatus() async -> NotificationAuthorization
}

/// 시스템 알림 권한을 화면이 쓰는 값으로 줄인 것 (GH-64 R-25)
enum NotificationAuthorization: Equatable {
    /// 허용 (임시·알림 요약 허용 포함)
    case authorized
    case denied
    /// 아직 묻지 않음
    case notDetermined
}

final class NotificationManager: NotificationManagerProtocol {
    static let shared = NotificationManager()

    private let nearbyAlertScheduler: NearbyAlertSchedulerProtocol

    init(nearbyAlertScheduler: NearbyAlertSchedulerProtocol = NearbyAlertScheduler.shared) {
        self.nearbyAlertScheduler = nearbyAlertScheduler
    }

    func reserveNotifications(wish: Wish) {
        // 동기화로 받은 위시·수정 저장한 위시도 켜져 있으면 다시 건다. 권한이 없으면 스케줄러가 건너뛴다 (GH-126 서버 저장 절)
        if wish.nearbyAlertOn {
            let scheduler = nearbyAlertScheduler
            Task { await scheduler.schedule(wish: wish) }
        }
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
        nearbyAlertScheduler.cancel(wishId: wish.id)
    }

    func authorizationStatus() async -> NotificationAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
    
    private func reserveNotification(
        title: String,
        deadline: Date,
        notification: SeepNotification
    ) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = Strings.notificationTitle
        notificationContent.body = Strings.notificationBodyFormat(title)
        notificationContent.sound = .default
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
                Logger(subsystem: "macgongmon.seep-ios", category: "NotificationManager")
                    .error("알림 예약 실패: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    private func cancelNotification(notification: SeepNotification) {
        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(withIdentifiers: [notification.id])
    }
}
