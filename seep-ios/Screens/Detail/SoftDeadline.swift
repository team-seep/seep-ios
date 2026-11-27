import Foundation

/// 기간 기한(이번 달 안·올해 안·내년까지)을 어떻게 보일지 (GH-118 R-4~R-6). UI 를 모르는 순수 타입이라 ViewModel·테스트에서 바로 쓴다.
/// 문구는 저장된 종류보다 오늘과 마감의 관계로 정한다 — "내년까지"로 정한 싶도 해가 바뀌면 "올해 안"이다.
/// 색은 날짜 기한과 같은 D-day 규칙을 마감(기간 마지막 날)에 그대로 쓴다 (R-4).
struct SoftDeadline: Equatable {
    enum Phase: Equatable {
        case thisMonth
        case thisYear
        case nextYear
        /// 이번 달 안에 기한이 지났다
        case monthOver
        /// 올해 안에·내년까지 기한이 지났다
        case yearOver
    }

    let kind: DeadlineKind
    let endDate: Date
    let phase: Phase

    /// 기간 기한이 아니거나(날짜·기한 없음), 오늘과 맞는 기간 문구가 없으면(내후년 이후 등) nil — D-day 로 보인다
    init?(endDate: Date?, kind: DeadlineKind, now: Date = Date(), calendar: Calendar = .current) {
        guard let endDate, kind.isPeriod else { return nil }
        self.kind = kind
        self.endDate = endDate

        let today = calendar.startOfDay(for: now)
        if calendar.startOfDay(for: endDate) < today {
            phase = kind == .month ? .monthOver : .yearOver
            return
        }
        let endYear = calendar.component(.year, from: endDate)
        let thisYear = calendar.component(.year, from: now)
        if kind == .month, calendar.isDate(endDate, equalTo: now, toGranularity: .month) {
            phase = .thisMonth
        } else if endYear == thisYear {
            phase = .thisYear
        } else if endYear == thisYear + 1 {
            phase = .nextYear
        } else {
            return nil
        }
    }

    init?(wish: Wish, now: Date = Date(), calendar: Calendar = .current) {
        self.init(endDate: wish.endDate, kind: wish.deadlineKind, now: now, calendar: calendar)
    }

    var isOver: Bool {
        switch phase {
        case .monthOver, .yearOver:
            return true
        case .thisMonth, .thisYear, .nextYear:
            return false
        }
    }

    /// 홈 뱃지 문구 (R-4, R-6)
    var badgeText: String {
        switch phase {
        case .thisMonth: return Strings.Deadline.Period.thisMonthBadge
        case .thisYear: return Strings.Deadline.Period.thisYearBadge
        case .nextYear: return Strings.Deadline.Period.nextYear
        case .monthOver: return Strings.Deadline.Period.monthOver
        case .yearOver: return Strings.Deadline.Period.yearOver
        }
    }

    /// 상세·작성 문서 D-day 줄 문구 (R-5, R-6)
    var lineText: String {
        switch phase {
        case .thisMonth: return Strings.Deadline.Period.thisMonth
        case .thisYear: return Strings.Deadline.Period.thisYear
        case .nextYear: return Strings.Deadline.Period.nextYear
        case .monthOver: return Strings.Deadline.Period.monthOver
        case .yearOver: return Strings.Deadline.Period.yearOver
        }
    }

    /// D-day 줄 보조 문구: "12월 31일까지" · 해가 다르면 "2027년 12월 31일까지" / 지났으면 "2026년 안에 하기로 했어요" (R-5, R-6)
    func dateText(now: Date = Date(), calendar: Calendar = .current, locale: Locale = AppLanguage.shared.locale) -> String {
        switch phase {
        case .thisMonth, .thisYear, .nextYear:
            return Self.untilText(endDate, now: now, calendar: calendar, locale: locale)
        case .monthOver:
            return Strings.Deadline.Period.promiseFormat(DisplayDate.string(endDate, template: "MMMM", locale: locale, calendar: calendar))
        case .yearOver:
            return Strings.Deadline.Period.promiseFormat(DisplayDate.string(endDate, template: "y", locale: locale, calendar: calendar))
        }
    }

    /// 지났을 때 미루기 버튼 문구 (R-6)
    var postponeTitle: String {
        return kind == .month ? Strings.Deadline.OverCard.postponeMonth : Strings.Deadline.OverCard.postponeYear
    }

    /// "12월 31일까지". 올해가 아니면 연도를 붙인다 (언제까지 시트 항목과 같은 표기)
    static func untilText(_ date: Date, now: Date, calendar: Calendar, locale: Locale) -> String {
        let isThisYear = calendar.isDate(date, equalTo: now, toGranularity: .year)
        let dateText = isThisYear
            ? DisplayDate.monthDay(date, locale: locale, calendar: calendar)
            : DisplayDate.yearMonthDay(date, locale: locale, calendar: calendar)
        return Strings.Detail.Dday.untilFormat(dateText)
    }
}
