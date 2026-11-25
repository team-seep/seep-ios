import Foundation

/// 잔디 한 칸 = 하루 (GH-146 R-1)
struct ActivityGrassCell: Equatable, Identifiable {
    /// 그날 0시
    let date: Date
    let count: Int
    /// 오늘 뒤의 날. 칸을 비워 둔다 (R-1)
    let isFuture: Bool

    var id: Date { date }
    var level: Int { ActivityGrass.level(count: count) }
}

/// 월 라벨. 그 달 1일이 든 주 칸 위에 둔다 (R-1)
struct ActivityGrassMonthLabel: Equatable, Identifiable {
    /// 보이는 주 안에서의 열 번호(0 = 가장 왼쪽)
    let column: Int
    /// 그 달 1일 0시
    let monthStart: Date

    var id: Int { column }
}

/// 이룬 싶 탭 "싶에 다가간 날" 잔디 (GH-146 R-1~R-3, R-8, R-9).
/// 넓은 화면을 위해 늘 최대 주 수(26주)를 만들고, 화면은 너비에 맞는 만큼 최근 주만 보여 준다
struct ActivityGrass: Equatable {
    static let minWeeks = 18
    static let maxWeeks = 26
    /// 칸 크기는 넓은 화면에서도 그대로 둔다 (R-9)
    static let cellSize: Double = 14
    static let cellSpacing: Double = 3
    /// 이 거리(열)보다 가까운 월 라벨은 겹치지 않게 뺀다
    private static let minLabelGap = 3

    /// 오래된 주부터 `maxWeeks`개. 주마다 7칸, 기기 달력의 첫 요일부터
    let weeks: [[ActivityGrassCell]]
    /// 올해 1월 1일부터 행동이 1건 이상인 날 수 (R-1)
    let yearDayCount: Int

    // MARK: 만들기

    /// 0 = 없음, 1 / 2 / 3 / 4 이상 = 4단계 (R-3)
    static func level(count: Int) -> Int {
        min(max(count, 0), 4)
    }

    /// 칸 크기를 그대로 두고 너비에 들어가는 주 수. 18주보다 적게, 26주보다 많이 보이지 않는다 (R-9)
    static func visibleWeekCount(contentWidth: Double) -> Int {
        let fit = Int(((contentWidth + cellSpacing) / (cellSize + cellSpacing)).rounded(.down))
        return min(max(fit, minWeeks), maxWeeks)
    }

    /// 읽어 올 범위: 보일 수 있는 가장 이른 날과 올해 1월 1일 중 이른 날 ~ 내일 0시
    static func fetchRange(today: Date, calendar: Calendar) -> (from: Date, to: Date) {
        let startOfToday = calendar.startOfDay(for: today)
        let firstDay = firstVisibleDay(today: today, calendar: calendar)
        let startOfYear = calendar.dateInterval(of: .year, for: today)?.start ?? startOfToday
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? today
        return (min(firstDay, startOfYear), tomorrow)
    }

    static func make(activities: [WishActivity], today: Date, calendar: Calendar) -> ActivityGrass {
        let startOfToday = calendar.startOfDay(for: today)
        let countByDay = Dictionary(grouping: activities) { calendar.startOfDay(for: $0.date) }.mapValues(\.count)
        let firstDay = firstVisibleDay(today: today, calendar: calendar)

        let weeks = (0..<maxWeeks).map { week in
            (0..<7).map { weekday -> ActivityGrassCell in
                let day = calendar.date(byAdding: .day, value: week * 7 + weekday, to: firstDay) ?? firstDay
                let date = calendar.startOfDay(for: day)
                return ActivityGrassCell(date: date, count: countByDay[date] ?? 0, isFuture: date > startOfToday)
            }
        }
        let year = calendar.component(.year, from: today)
        let yearDayCount = countByDay.keys.filter { calendar.component(.year, from: $0) == year && $0 <= startOfToday }.count
        return ActivityGrass(weeks: weeks, yearDayCount: yearDayCount)
    }

    // MARK: 보여 주기

    func visibleWeeks(_ count: Int) -> [[ActivityGrassCell]] {
        Array(weeks.suffix(count))
    }

    /// 보이는 주 안에서 행동이 1건 이상인 날 수 (R-8 요약)
    func activeDayCount(inLast weekCount: Int) -> Int {
        visibleWeeks(weekCount).joined().filter { !$0.isFuture && $0.count > 0 }.count
    }

    func monthLabels(inLast weekCount: Int, calendar: Calendar) -> [ActivityGrassMonthLabel] {
        var labels: [ActivityGrassMonthLabel] = []
        for (column, week) in visibleWeeks(weekCount).enumerated() {
            guard let first = week.first(where: { calendar.component(.day, from: $0.date) == 1 }) else { continue }
            if let last = labels.last, column - last.column < Self.minLabelGap { continue }
            labels.append(ActivityGrassMonthLabel(column: column, monthStart: first.date))
        }
        return labels
    }

    // MARK: VoiceOver (R-8)

    /// "11월 18일 (화), 3번"
    static func accessibilityLabel(for cell: ActivityGrassCell, locale: Locale = AppLanguage.shared.locale, calendar: Calendar = .current) -> String {
        Strings.Finished.ActivityGrass.cellAccessibilityFormat(
            DisplayDate.monthDayWeekday(cell.date, locale: locale, calendar: calendar),
            cell.count
        )
    }

    /// "최근 18주 중 5일 싶에 다가갔어요"
    func summaryAccessibilityLabel(weekCount: Int) -> String {
        Strings.Finished.ActivityGrass.summaryAccessibilityFormat(weekCount, activeDayCount(inLast: weekCount))
    }

    // MARK: Private

    /// 가장 왼쪽 열 = 오늘이 든 주에서 (최대 주 수 - 1)주 전 주의 첫날
    private static func firstVisibleDay(today: Date, calendar: Calendar) -> Date {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? calendar.startOfDay(for: today)
        return calendar.date(byAdding: .day, value: -(maxWeeks - 1) * 7, to: weekStart) ?? weekStart
    }
}
