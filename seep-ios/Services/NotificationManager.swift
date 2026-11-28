import os
import UserNotifications


protocol NotificationManagerProtocol {
    /// D-day 알림과 적금 계획 넣는 날 알림(GH-121)을 위시 상태에 맞춰 예약한다. 계획 알림이 필요 없는 상태면 지운다
    func reserveNotifications(wish: Wish)
    
    /// D-day 알림과 적금 계획 넣는 날 알림을 모두 지운다
    func cancelNotifications(wish: Wish)

    /// 적금 계획 넣는 날 알림만 위시 상태에 맞춘다(필요하면 예약, 아니면 지움). 계획 저장·지우기·모은 돈 기록 뒤에 부른다 (GH-121 R-6)
    func updateSavingPlanNotification(wish: Wish)

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

/// 로컬 알림을 실제로 넣고 빼는 곳. 테스트는 가짜로 바꿔 예약 요청을 확인한다 (GH-121)
protocol LocalNotificationScheduling {
    func add(request: UNNotificationRequest)
    func removePendingRequests(identifiers: [String])
}

struct SystemNotificationScheduler: LocalNotificationScheduling {
    func add(request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger(subsystem: "macgongmon.seep-ios", category: "NotificationManager")
                    .error("알림 예약 실패: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func removePendingRequests(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

final class NotificationManager: NotificationManagerProtocol {
    static let shared = NotificationManager()

    private let scheduler: LocalNotificationScheduling

    init(scheduler: LocalNotificationScheduling = SystemNotificationScheduler()) {
        self.scheduler = scheduler
    }
    
    func reserveNotifications(wish: Wish) {
        updateSavingPlanNotification(wish: wish)
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
        scheduler.removePendingRequests(identifiers: SavingPlanNotification.identifiers(wishId: wish.id))
    }

    func updateSavingPlanNotification(wish: Wish) {
        // 주기·날을 바꿨을 수 있어 예전 요청을 모두 지우고 지금 계획으로 다시 넣는다
        scheduler.removePendingRequests(identifiers: SavingPlanNotification.identifiers(wishId: wish.id))
        for request in SavingPlanNotification.requests(wish: wish) {
            scheduler.add(request: request)
        }
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
        
        scheduler.add(request: request)
    }
    
    private func cancelNotification(notification: SeepNotification) {
        scheduler.removePendingRequests(identifiers: [notification.id])
    }
}
