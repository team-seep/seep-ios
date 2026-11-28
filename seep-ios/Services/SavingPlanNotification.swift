import Foundation
import UserNotifications

/// 적금 계획 넣는 날 반복 알림 (GH-121 R-6). 예약·취소 판단을 한곳에 모아 `NotificationManager`의 모든 경로가 같은 규칙을 쓴다
enum SavingPlanNotification {
    /// 넣는 날 오전 11시
    static let hour = 11
    /// 알림 `userInfo`에 넣는 위시 상세 링크 키. 앱이 알림을 누르면 이 링크로 상세를 연다
    static let deepLinkKey = "deepLink"

    /// 위시 하나가 쓸 수 있는 알림 id 전부. 주기를 바꿔도 남지 않게 지울 때는 모두 지운다
    static func identifiers(wishId: String) -> [String] {
        [baseIdentifier(wishId: wishId)] + (1...12).map { monthIdentifier(wishId: wishId, month: $0) }
    }

    /// 아직 이루지 않은 갖고 싶어요 + 목표 금액 + 계획이 있고, 목표를 다 모으지 않았을 때만 울린다
    static func isActive(wish: Wish) -> Bool {
        guard !wish.isSuccess, wish.category == .wantToGet, wish.savingPlan != nil,
              let progress = WishSavingProgress(targetAmount: wish.targetAmount, savings: wish.savings, currency: wish.currency) else {
            return false
        }
        return !progress.isCompleted
    }

    static func requests(wish: Wish) -> [UNNotificationRequest] {
        guard isActive(wish: wish), let plan = wish.savingPlan else { return [] }
        let content = makeContent(wish: wish, plan: plan)
        return triggers(plan: plan).map { identifier, components in
            UNNotificationRequest(
                identifier: identifier(wish.id),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            )
        }
    }

    /// 매주 = 요일 반복 1건. 매달 = 날짜 반복 1건 + (29~31일이면) 그 날짜가 없는 달마다 그 달 마지막 날 반복.
    /// 2월은 평년 기준 28일로 둔다 — 윤년에는 29일 계획이 28·29일 두 번, 30·31일 계획이 하루 일찍(28일) 울린다
    static func triggers(plan: SavingPlan) -> [(identifier: (String) -> String, components: DateComponents)] {
        switch plan.cycle {
        case .weekly:
            return [(baseIdentifier, DateComponents(hour: hour, minute: 0, weekday: plan.day))]
        case .monthly:
            let base: (identifier: (String) -> String, components: DateComponents) = (
                baseIdentifier, DateComponents(day: plan.day, hour: hour, minute: 0)
            )
            let shortMonths = (1...12).compactMap { month -> (identifier: (String) -> String, components: DateComponents)? in
                let lastDay = daysInMonth(month)
                guard lastDay < plan.day else { return nil }
                return ({ monthIdentifier(wishId: $0, month: month) }, DateComponents(month: month, day: lastDay, hour: hour, minute: 0))
            }
            return [base] + shortMonths
        }
    }

    private static func makeContent(wish: Wish, plan: SavingPlan) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = Strings.notificationTitle
        let name = "\(wish.emoji) \(wish.title)".trimmingCharacters(in: .whitespaces)
        content.body = Strings.Detail.SavingPlan.notificationBodyFormat(
            name,
            AmountFormatter.money(plan.amount, currency: wish.currency)
        )
        content.sound = .default
        if let url = WidgetDeepLink.wish(id: wish.id, source: .savingPlanNotification).url {
            content.userInfo = [deepLinkKey: url.absoluteString]
        }
        return content
    }

    private static func baseIdentifier(wishId: String) -> String {
        "savingPlan-\(wishId)"
    }

    private static func monthIdentifier(wishId: String, month: Int) -> String {
        "savingPlan-\(wishId)-m\(month)"
    }

    /// 평년 기준 달의 날 수
    private static func daysInMonth(_ month: Int) -> Int {
        switch month {
        case 2:
            return 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
}
