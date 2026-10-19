import Foundation

/// 오래 손대지 않은 미완료 위시("잠든 위시")를 고르는 규칙 (GH-30 R-3, R-4).
/// 오늘 날짜를 밖에서 받는 순수 함수라 기기 시간과 상관없이 유닛 테스트한다.
enum SleepingWishPolicy {
    /// 마지막으로 손댄 날로부터 이 일수 이상 지나면 잠든 위시다
    static let thresholdDays = 60

    /// 마지막으로 손댄 날 = 점검(여전히 하고 싶어요·수정 저장)한 시각, 없으면 만든 시각
    static func lastTouchedAt(_ wish: Wish) -> Date {
        return wish.lastCheckedAt ?? wish.createdAt
    }

    /// 마지막으로 손댄 날부터 오늘까지 지난 달력 날짜 수
    static func daysSinceTouched(_ wish: Wish, today: Date, calendar: Calendar = .current) -> Int {
        let from = calendar.startOfDay(for: lastTouchedAt(wish))
        let to = calendar.startOfDay(for: today)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    static func isSleeping(_ wish: Wish, today: Date, calendar: Calendar = .current) -> Bool {
        guard !wish.isSuccess else { return false }
        guard daysSinceTouched(wish, today: today, calendar: calendar) >= thresholdDays else { return false }

        // 마감일이 오늘이거나 앞으로 남은 위시는 계획대로 기다리는 중이다
        if let endDate = wish.endDate {
            return calendar.startOfDay(for: endDate) < calendar.startOfDay(for: today)
        }
        return true
    }

    /// 잠든 위시 중 마지막으로 손댄 날이 가장 이른 1개. 없으면 nil
    static func oldestSleepingWish(in wishes: [Wish], today: Date, calendar: Calendar = .current) -> Wish? {
        return wishes
            .filter { isSleeping($0, today: today, calendar: calendar) }
            .min { lastTouchedAt($0) < lastTouchedAt($1) }
    }
}
