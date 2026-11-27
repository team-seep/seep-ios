import Foundation

/// 기한 종류 (GH-118 R-1). 기간 기한은 `date`에 그 기간의 마지막 날을 저장해서
/// D-day 정렬·알림·캘린더 추가가 날짜 기한과 똑같이 돈다 (R-2).
/// 저장 값: "" 또는 "date" = 날짜(예전 위시 포함), "month" = 이번 달 안, "year" = 올해 안, "next_year" = 내년까지
enum DeadlineKind: String, CaseIterable {
    case date = ""
    case month
    case year
    case nextYear = "next_year"

    /// 모르는 값(더 새 앱이 쓴 값 등)·"date"는 날짜 기한으로 본다
    init(stored: String) {
        self = DeadlineKind(rawValue: stored) ?? .date
    }

    var isPeriod: Bool {
        return self != .date
    }

    /// 저장된 마감을 이 기기에서 쓸 기간 마지막 날로 맞춘다. 기간 종류가 아니면 그대로, 맞출 수 없으면 nil (GH-118 R-11).
    /// - 마감은 저장한 기기 시간대의 23:59:59 라 다른 시간대 기기에서는 하루 앞뒤로 보인다 → 그 기간의 마지막 날로 옮긴다.
    ///   그래야 문구·지남 판정·미루기가 같은 기간을 본다.
    /// - 기간 종류를 모르는 구버전 앱이 날짜만 바꿔 동기화하면 "올해 안"인데 3월 5일 같은 값이 생긴다 → nil(날짜 기한으로 읽는다)
    func normalizedEnd(_ endDate: Date?, calendar: Calendar = .current) -> Date? {
        guard isPeriod else { return endDate }
        guard let endDate else { return nil }
        let unit: Calendar.Component = self == .month ? .month : .year
        for offset in [0, -1, 1] {
            guard let shifted = calendar.date(byAdding: .day, value: offset, to: endDate),
                  let end = Self.lastMoment(of: unit, containing: shifted, calendar: calendar) else { continue }
            if calendar.isDate(shifted, inSameDayAs: end) { return end }
        }
        return nil
    }

    /// 지금 고르면 저장할 마감: 그 기간 마지막 날의 끝(23:59:59). 날짜 기한은 nil (R-2)
    func periodEnd(from now: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .date:
            return nil
        case .month:
            return Self.lastMoment(of: .month, containing: now, calendar: calendar)
        case .year:
            return Self.lastMoment(of: .year, containing: now, calendar: calendar)
        case .nextYear:
            guard let nextYear = calendar.date(byAdding: .year, value: 1, to: now) else { return nil }
            return Self.lastMoment(of: .year, containing: nextYear, calendar: calendar)
        }
    }

    /// 지난 기간을 한 번 미룬 마감 (R-6). 이번 달 → 다음 달 말일, 올해·내년 → 마감 다음 해 12월 31일.
    /// 한참 지나 열어서 그래도 지난 날이면 오늘이 든 기간까지 민다 — 미루자마자 또 지난 기한이 되지 않게
    func postponedEnd(from deadline: Date, now: Date, calendar: Calendar = .current) -> Date? {
        let unit: Calendar.Component
        switch self {
        case .date:
            return nil
        case .month:
            unit = .month
        case .year, .nextYear:
            unit = .year
        }
        let today = calendar.startOfDay(for: now)
        var end = deadline
        // 기간 하나씩 민다. 그래도 지난 날이면 한 번 더 (먼 과거 값이어도 끝나게 횟수를 막는다)
        for _ in 0..<1_200 {
            guard let next = calendar.date(byAdding: unit, value: 1, to: calendar.startOfDay(for: end)),
                  let nextEnd = Self.lastMoment(of: unit, containing: next, calendar: calendar) else { return nil }
            end = nextEnd
            if end >= today { return end }
        }
        return nil
    }

    private static func lastMoment(of unit: Calendar.Component, containing date: Date, calendar: Calendar) -> Date? {
        guard let interval = calendar.dateInterval(of: unit, for: date) else { return nil }
        return interval.end.addingTimeInterval(-1)
    }
}
