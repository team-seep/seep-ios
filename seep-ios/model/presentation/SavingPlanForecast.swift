import Foundation

/// 적금 계획의 넣는 날 계산 (GH-121 R-3). 날짜는 그 달력의 하루 시작(자정)으로 센다
enum SavingPlanSchedule {
    /// 오늘을 포함해 오늘 이후 `index`번째(0부터) 넣는 날.
    /// 매달 31일처럼 그 달에 없는 날짜는 그 달 마지막 날로 센다.
    /// - Parameter skipsToday: 오늘 이미 기록했으면 오늘 회차는 넣은 것으로 보고 내일부터 센다
    static func paymentDate(plan: SavingPlan, index: Int, now: Date, calendar: Calendar, skipsToday: Bool = false) -> Date? {
        guard index >= 0 else { return nil }
        let startOfToday = calendar.startOfDay(for: now)
        guard let today = skipsToday ? calendar.date(byAdding: .day, value: 1, to: startOfToday) : startOfToday else { return nil }
        switch plan.cycle {
        case .weekly:
            let weekday = calendar.component(.weekday, from: today)
            let daysUntilFirst = (plan.day - weekday + 7) % 7
            return calendar.date(byAdding: .day, value: daysUntilFirst + index * 7, to: today)
        case .monthly:
            guard let thisMonth = clampedMonthlyDate(day: plan.day, monthOffset: 0, today: today, calendar: calendar) else { return nil }
            let firstOffset = thisMonth >= today ? 0 : 1
            return clampedMonthlyDate(day: plan.day, monthOffset: firstOffset + index, today: today, calendar: calendar)
        }
    }

    private static func clampedMonthlyDate(day: Int, monthOffset: Int, today: Date, calendar: Calendar) -> Date? {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: monthStart),
              let days = calendar.range(of: .day, in: .month, for: targetMonth) else { return nil }
        return calendar.date(byAdding: .day, value: min(day, days.count) - 1, to: targetMonth)
    }
}

/// 계획대로 넣으면 언제 다 모이는지 (GH-121 R-3, R-4). 이미 다 모았으면 만들지 않는다
struct SavingPlanForecast: Equatable {
    /// 기한과 다 모이는 날 비교 (R-4)
    enum DeadlineGap: Equatable {
        case earlier(days: Int)
        case later(days: Int)
        case onTime
    }

    /// 앞으로 넣을 횟수 = ceil(남은 금액 / 한 번 금액)
    let depositCount: Int
    let completionDate: Date
    let nextPaymentDate: Date
    /// 기한이 없으면 nil
    let deadlineGap: DeadlineGap?

    /// - Parameter savedToday: 오늘 기록이 있으면 오늘 넣는 날은 이미 넣은 것으로 보고 다음 회차부터 센다
    init?(plan: SavingPlan, remainingAmount: Int, deadline: Date?, now: Date, calendar: Calendar, savedToday: Bool = false) {
        guard remainingAmount > 0 else { return nil }
        let count = (remainingAmount + plan.amount - 1) / plan.amount
        let date: (Int) -> Date? = {
            SavingPlanSchedule.paymentDate(plan: plan, index: $0, now: now, calendar: calendar, skipsToday: savedToday)
        }
        // 10년 넘게 걸리는 계획은 예측이 의미 없어 숨긴다(속도 예측과 같은 상한)
        guard let next = date(0), let completion = date(count - 1),
              (calendar.dateComponents([.day], from: next, to: completion).day ?? 0) <= SavingPaceForecast.maxDays else {
            return nil
        }
        self.depositCount = count
        self.completionDate = completion
        self.nextPaymentDate = next
        self.deadlineGap = deadline.flatMap { deadline in
            let days = calendar.dateComponents([.day], from: completion, to: calendar.startOfDay(for: deadline)).day ?? 0
            if days > 0 { return .earlier(days: days) }
            if days < 0 { return .later(days: -days) }
            return .onTime
        }
    }
}

/// 계획 없이 지금까지 기록한 평균 속도로 본 예측 (GH-121 R-5)
struct SavingPaceForecast: Equatable {
    /// 이보다 멀면 예측이 의미 없어 숨긴다 (10년)
    static let maxDays = 3_650

    let completionDate: Date

    /// 기록이 2건 이상이고 아직 덜 모았을 때만. 속도 = 첫 기록~오늘 모은 금액 / 날 수(최소 1일)
    init?(savings: [WishSaving], remainingAmount: Int, now: Date, calendar: Calendar) {
        guard savings.count >= 2, remainingAmount > 0,
              let firstDate = savings.map(\.createdAt).min() else { return nil }
        let today = calendar.startOfDay(for: now)
        let elapsedDays = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: firstDate), to: today).day ?? 0, 1)
        let savedAmount = savings.reduce(0) { $0 + $1.amount }
        guard savedAmount > 0 else { return nil }
        let perDay = Double(savedAmount) / Double(elapsedDays)
        let needDays = (Double(remainingAmount) / perDay).rounded(.up)
        guard needDays <= Double(Self.maxDays),
              let date = calendar.date(byAdding: .day, value: Int(needDays), to: today) else { return nil }
        self.completionDate = date
    }
}
