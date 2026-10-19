import Foundation

/// 완료 위시로 배지 8종의 상태를 계산하는 순수 함수 (GH-35 R-1~R-3).
enum BadgeCalculator {
    static func calculate(finishedWishes: [Wish], calendar: Calendar = .current) -> [Badge] {
        let finished = finishedWishes
            .filter(\.isSuccess)
            .sorted { finishDate(of: $0) < finishDate(of: $1) }
        let finishedCount = finished.count

        return BadgeType.allCases.map { type in
            Badge(
                type: type,
                earnedDate: earnedDate(type: type, finished: finished, calendar: calendar),
                finishedCount: finishedCount
            )
        }
    }

    /// `finished` 는 완료일 오름차순
    private static func earnedDate(type: BadgeType, finished: [Wish], calendar: Calendar) -> Date? {
        if let goalCount = type.goalCount {
            guard finished.count >= goalCount else { return nil }
            return finishDate(of: finished[goalCount - 1])
        }

        if let category = type.category {
            return finished.first { $0.category == category }.map(finishDate(of:))
        }

        return finished.first { isOnTime($0, calendar: calendar) }.map(finishDate(of:))
    }

    /// 마감일이 있고, 완료한 날이 마감일 당일 또는 그 전이면 약속을 지킨 것이다 (R-1 on_time)
    private static func isOnTime(_ wish: Wish, calendar: Calendar) -> Bool {
        guard let endDate = wish.endDate, let finishDate = wish.finishDate else { return false }
        return calendar.startOfDay(for: finishDate) <= calendar.startOfDay(for: endDate)
    }

    /// 완료일이 없는 옛 완료 데이터는 작성일로 대신한다 (R-2)
    private static func finishDate(of wish: Wish) -> Date {
        return wish.finishDate ?? wish.createdAt
    }
}
