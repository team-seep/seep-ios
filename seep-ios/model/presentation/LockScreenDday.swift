import Foundation

/// 잠금화면 "다가오는 싶 D-day" 위젯이 보여줄 위시를 고른다. 위젯·앱이 같이 쓴다 (GH-47 R-2, R-12)
enum LockScreenDdayPicker {
    /// 완료하지 않았고 날짜가 오늘 이후(오늘 포함)인 위시 중 날짜가 가장 이른 것. 같은 날이면 먼저 만든 것.
    static func pick(wishes: [Wish], now: Date, calendar: Calendar = .current) -> Wish? {
        let today = calendar.startOfDay(for: now)
        let candidates: [(wish: Wish, day: Date)] = wishes.compactMap { wish in
            guard !wish.isSuccess, let endDate = wish.endDate else { return nil }
            let day = calendar.startOfDay(for: endDate)
            return day >= today ? (wish, day) : nil
        }

        return candidates.min { lhs, rhs in
            if lhs.day != rhs.day {
                return lhs.day < rhs.day
            }
            return lhs.wish.createdAt < rhs.wish.createdAt
        }?.wish
    }

    /// D-n 이 날마다 바뀌도록 위젯 타임라인을 다음 날 0시에 갱신한다 (GH-47 R-9)
    static func nextRefreshDate(after now: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: today) ?? now.addingTimeInterval(24 * 60 * 60)
    }

    /// 빈 상태 한 줄 위젯 문구 (GH-47 R-6)
    static func remainText(count: Int) -> String {
        return Strings.Widget.LockScreen.remainFormat(count)
    }
}

/// 잠금화면 위젯의 D-day 문구. 앱 `DdayLabel` 과 같은 기준(365일 넘으면 "먼훗날")을 쓴다 (GH-47 R-3~R-5)
struct DdayText: Equatable {
    /// 남은 날 수. 0 이면 오늘
    let remainDay: Int
    /// "D-3", "먼훗날"
    let dday: String
    /// 직사각형 3행. "10월 22일 (목)까지", "오늘까지", "2028년 8월 1일까지"
    let dueText: String

    static let farFutureDays = 365

    static func make(endDate: Date, now: Date, calendar: Calendar = .current, locale: Locale = .current) -> DdayText {
        let remainDay = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: endDate)
        ).day ?? 0

        let dday: String
        let dueText: String
        if remainDay > farFutureDays {
            dday = Strings.homeInFarFurture
            dueText = Strings.Detail.Dday.untilFormat(DisplayDate.yearMonthDay(endDate, locale: locale, calendar: calendar))
        } else if remainDay == 0 {
            dday = "D-0"
            dueText = Strings.Detail.Dday.untilToday
        } else {
            dday = remainDay < 0 ? "D+\(-remainDay)" : "D-\(remainDay)"
            dueText = Strings.Detail.Dday.untilFormat(DisplayDate.monthDayWeekday(endDate, locale: locale, calendar: calendar))
        }

        return DdayText(remainDay: remainDay, dday: dday, dueText: dueText)
    }
}
