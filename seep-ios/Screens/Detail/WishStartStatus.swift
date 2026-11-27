import Foundation

/// 상세 상태 줄 — 시작 전 / 하는 중 / 이룬 싶의 시작 기록 (GH-143 R-2, R-6).
/// 위시 → 문구로만 바꿔 유닛 테스트한다. 시작 기록이 없는 이룬 싶은 nil(상태 줄을 그리지 않는다)
enum WishStartStatus: Equatable {
    /// "아직 시작 전이에요" + "시작했어요"
    case notStarted
    /// "하고 있어요 · {sinceText}" + "되돌리기"
    case doing(sinceText: String, days: Int)
    /// "{시작일}에 시작 · {n}일 만에 이뤘어요" (누를 것 없음)
    case finished(text: String)

    init?(wish: Wish, now: Date, calendar: Calendar = .current, locale: Locale = AppLanguage.shared.locale) {
        guard let startedAt = wish.startedAt else {
            if wish.isSuccess { return nil }
            self = .notStarted
            return
        }
        let startText = DisplayDate.monthDay(startedAt, locale: locale, calendar: calendar)
        if wish.isSuccess {
            let days = Self.dayNumber(since: startedAt, on: wish.finishDate ?? now, calendar: calendar)
            self = .finished(text: Strings.Detail.Start.finishedFormat(startText, days))
        } else {
            let days = Self.dayNumber(since: startedAt, on: now, calendar: calendar)
            self = .doing(sinceText: Strings.Detail.Start.sinceFormat(startText, days), days: days)
        }
    }

    /// 시작한 날을 1일째로 센 날수. 시각이 아니라 기기 시간대의 달력 날짜로 센다 (R-2, TC-4)
    static func dayNumber(since start: Date, on date: Date, calendar: Calendar = .current) -> Int {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: date)).day ?? 0
        // 다른 기기 시계가 앞서 미래 시각이 왔어도 0일째·음수로 보이지 않게 한다
        return max(days, 0) + 1
    }

    /// '하는 중' 싶의 "n일째". 시작 전·이룬 싶은 nil (홈 셀 R-5)
    static func inProgressDays(of wish: Wish, now: Date, calendar: Calendar = .current) -> Int? {
        guard wish.isInProgress, let startedAt = wish.startedAt else { return nil }
        return dayNumber(since: startedAt, on: now, calendar: calendar)
    }
}
