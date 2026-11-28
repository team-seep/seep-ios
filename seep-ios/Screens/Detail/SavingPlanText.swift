import Foundation

/// 적금 계획 줄·시트 미리보기에 보이는 문구 (GH-121 R-3~R-5). 날짜는 `DisplayDate` 로케일 템플릿을 쓴다
enum SavingPlanText {
    /// 상세 계획 줄 한 묶음. 계획 요약 / 예측(굵게 칠할 날짜 포함) / 기한 비교·다음 넣는 날
    struct Row: Equatable {
        /// "매주 금요일 30,000원씩". 계획이 없으면 nil
        var summary: String?
        /// "7번 넣으면 12월 18일 (금)에 다 모여요" 또는 "지금 속도라면 12월 3일쯤 다 모여요"
        var forecast: String?
        /// `forecast` 안에서 굵게 칠할 날짜
        var forecastHighlight: String?
        /// "기한보다 13일 먼저예요 · 다음 넣는 날 11월 6일"
        var meta: String?
    }

    static func row(
        plan: SavingPlan?,
        savings: [WishSaving],
        remainingAmount: Int,
        currency: String,
        deadline: Date?,
        now: Date,
        calendar: Calendar
    ) -> Row {
        guard let plan else {
            guard let pace = SavingPaceForecast(savings: savings, remainingAmount: remainingAmount, now: now, calendar: calendar) else {
                return Row()
            }
            let date = shortDate(pace.completionDate, now: now, calendar: calendar)
            return Row(forecast: Strings.Detail.SavingPlan.paceFormat(date), forecastHighlight: date)
        }
        var row = Row(summary: summary(plan: plan, currency: currency, calendar: calendar))
        guard let forecast = SavingPlanForecast(
            plan: plan,
            remainingAmount: remainingAmount,
            deadline: deadline,
            now: now,
            calendar: calendar
        ) else { return row }
        let completion = forecastSentence(forecast, now: now, calendar: calendar)
        row.forecast = completion.text
        row.forecastHighlight = completion.highlight
        row.meta = meta(forecast, now: now, calendar: calendar)
        return row
    }

    /// "매주 금요일 30,000원씩" / "매달 25일 30,000원씩"
    static func summary(plan: SavingPlan, currency: String, calendar: Calendar) -> String {
        let money = AmountFormatter.money(plan.amount, currency: currency)
        switch plan.cycle {
        case .weekly:
            return Strings.Detail.SavingPlan.weeklyFormat(weekdayName(plan.day, calendar: calendar), money)
        case .monthly:
            return Strings.Detail.SavingPlan.monthlyFormat(plan.day, money)
        }
    }

    /// "7번 넣으면 12월 18일 (금)에 다 모여요" + 굵게 칠할 날짜
    static func forecastSentence(_ forecast: SavingPlanForecast, now: Date, calendar: Calendar) -> (text: String, highlight: String) {
        let date = longDate(forecast.completionDate, now: now, calendar: calendar)
        return (Strings.Detail.SavingPlan.forecastFormat(forecast.depositCount, date), date)
    }

    /// "기한보다 13일 먼저예요 · 다음 넣는 날 11월 6일". 기한이 없으면 "다음 넣는 날 11월 6일"
    static func meta(_ forecast: SavingPlanForecast, now: Date, calendar: Calendar) -> String {
        let next = Strings.Detail.SavingPlan.nextFormat(shortDate(forecast.nextPaymentDate, now: now, calendar: calendar))
        guard let gap = forecast.deadlineGap else { return next }
        let gapText: String
        switch gap {
        case .earlier(let days):
            gapText = Strings.Detail.SavingPlan.deadlineEarlierFormat(days)
        case .later(let days):
            gapText = Strings.Detail.SavingPlan.deadlineLaterFormat(days)
        case .onTime:
            gapText = Strings.Detail.SavingPlan.deadlineOnTime
        }
        return Strings.Detail.SavingPlan.metaJoinFormat(gapText, next)
    }

    /// 요일 이름("금요일"). `day`는 `Calendar` weekday(1=일요일)
    static func weekdayName(_ day: Int, calendar: Calendar) -> String {
        symbol(day, symbols: formatter(calendar: calendar).standaloneWeekdaySymbols)
    }

    /// 요일 칩 글자("금")
    static func shortWeekdayName(_ day: Int, calendar: Calendar) -> String {
        symbol(day, symbols: formatter(calendar: calendar).shortStandaloneWeekdaySymbols)
    }

    /// 올해면 "12월 18일 (금)", 다른 해면 "2027년 3월 5일 (금)"
    private static func longDate(_ date: Date, now: Date, calendar: Calendar) -> String {
        isSameYear(date, now, calendar: calendar)
            ? DisplayDate.monthDayWeekday(date, calendar: calendar)
            : DisplayDate.yearMonthDayWeekday(date, calendar: calendar)
    }

    /// 올해면 "11월 6일", 다른 해면 "2027년 1월 3일"
    private static func shortDate(_ date: Date, now: Date, calendar: Calendar) -> String {
        isSameYear(date, now, calendar: calendar)
            ? DisplayDate.monthDay(date, calendar: calendar)
            : DisplayDate.yearMonthDay(date, calendar: calendar)
    }

    private static func isSameYear(_ lhs: Date, _ rhs: Date, calendar: Calendar) -> Bool {
        calendar.component(.year, from: lhs) == calendar.component(.year, from: rhs)
    }

    private static func formatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.shared.locale
        formatter.calendar = calendar
        return formatter
    }

    private static func symbol(_ day: Int, symbols: [String]?) -> String {
        guard let symbols, symbols.indices.contains(day - 1) else { return "" }
        return symbols[day - 1]
    }
}
