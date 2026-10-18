import Foundation

/// 한 해 동안 이룬 싶 결산 (GH-34 R-3, R-4). 기기 달력·시간대 기준으로 집계하는 순수 값이다.
struct YearReviewSummary: Equatable {
    struct LongestHeld: Equatable {
        let wish: Wish
        /// 적은 날부터 이룬 날까지 달력 일수
        let days: Int
    }

    struct BusiestMonth: Equatable {
        let month: Int
        let count: Int
    }

    struct MonthGroup: Equatable {
        let month: Int
        /// 완료일 내림차순
        let wishes: [Wish]
    }

    let year: Int
    /// 대상 연도에 완료한 위시, 완료일 내림차순
    let wishes: [Wish]
    let longestHeld: LongestHeld?
    /// 완료가 1개뿐이면 nil (R-4)
    let busiestMonth: BusiestMonth?
    /// 소감이 있는 위시 중 가장 최근에 완료한 것. 없으면 nil
    let noteOfYear: Wish?
    /// 달 내림차순 (R-6)
    let monthGroups: [MonthGroup]

    var totalCount: Int { wishes.count }

    func count(of category: Category) -> Int {
        wishes.filter { $0.category == category }.count
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        // Wish 의 == 는 id 만 비교하므로 목록은 id 순서로 비교한다
        lhs.year == rhs.year
            && lhs.wishes.map(\.id) == rhs.wishes.map(\.id)
            && lhs.longestHeld == rhs.longestHeld
            && lhs.busiestMonth == rhs.busiestMonth
            && lhs.noteOfYear?.id == rhs.noteOfYear?.id
            && lhs.monthGroups == rhs.monthGroups
    }
}

extension YearReviewSummary {
    /// 완료(`isSuccess`) + `finishDate`가 `year` 안인 위시만 집계한다. 다른 해·미완료 위시는 넘겨도 빠진다.
    static func make(wishes: [Wish], year: Int, calendar: Calendar) -> YearReviewSummary {
        let finished: [(wish: Wish, finishDate: Date)] = wishes
            .compactMap { wish in
                guard wish.isSuccess, let finishDate = wish.finishDate,
                      calendar.component(.year, from: finishDate) == year else { return nil }
                return (wish, finishDate)
            }
            .sorted { $0.finishDate > $1.finishDate }

        return YearReviewSummary(
            year: year,
            wishes: finished.map(\.wish),
            longestHeld: longestHeld(finished, calendar: calendar),
            busiestMonth: busiestMonth(finished, calendar: calendar),
            noteOfYear: finished.first { !$0.wish.finishNote.isEmpty }?.wish,
            monthGroups: monthGroups(finished, calendar: calendar)
        )
    }

    /// 대상 연도의 집계 구간 [1월 1일 00:00, 다음 해 1월 1일 00:00)
    static func dateRange(year: Int, calendar: Calendar) -> (from: Date, to: Date)? {
        guard let from = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let to = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else { return nil }
        return (from, to)
    }

    /// 회고 배너를 띄우는 기간이면 대상 연도를 돌려준다 (R-1). 12월이면 그 해, 1월이면 지난해, 그 밖엔 nil
    static func targetYear(now: Date, calendar: Calendar) -> Int? {
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let year = components.year, let month = components.month else { return nil }

        switch month {
        case 12:
            return year
        case 1:
            return year - 1
        default:
            return nil
        }
    }

    private static func longestHeld(_ finished: [(wish: Wish, finishDate: Date)], calendar: Calendar) -> LongestHeld? {
        // 완료일 오름차순으로 훑어 "더 클 때만" 바꾸면 동률은 먼저 완료한 것이 남는다
        var result: LongestHeld?
        for item in finished.reversed() {
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: item.wish.createdAt),
                to: calendar.startOfDay(for: item.finishDate)
            ).day ?? 0
            if days > (result?.days ?? -1) {
                result = LongestHeld(wish: item.wish, days: days)
            }
        }
        return result
    }

    private static func busiestMonth(_ finished: [(wish: Wish, finishDate: Date)], calendar: Calendar) -> BusiestMonth? {
        guard finished.count > 1 else { return nil }
        let countByMonth = Dictionary(grouping: finished) { calendar.component(.month, from: $0.finishDate) }
            .mapValues(\.count)
        // 이른 달부터 훑어 "더 클 때만" 바꾸면 동률은 이른 달이 남는다
        var result: BusiestMonth?
        for month in countByMonth.keys.sorted() {
            let count = countByMonth[month] ?? 0
            if count > (result?.count ?? 0) {
                result = BusiestMonth(month: month, count: count)
            }
        }
        return result
    }

    private static func monthGroups(_ finished: [(wish: Wish, finishDate: Date)], calendar: Calendar) -> [MonthGroup] {
        let grouped = Dictionary(grouping: finished) { calendar.component(.month, from: $0.finishDate) }
        return grouped.keys.sorted(by: >).map { month in
            MonthGroup(month: month, wishes: (grouped[month] ?? []).map(\.wish))
        }
    }
}
