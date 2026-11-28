import Foundation

/// 모은 돈 기록 한 건 (GH-16).
struct WishSaving: Equatable, Hashable {
    /// 목표 금액·기록 금액 상한. 통화의 최소 단위 기준(원화 10억 원 미만, 달러 1천만 달러 미만) (R-2·R-4, GH-103 R-17)
    static let maxAmount = 999_999_999

    let id: String
    let amount: Int
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        amount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.createdAt = createdAt
    }

    /// 최신 기록이 먼저 오도록 정렬한다 (R-3).
    static func latestFirst(_ savings: [WishSaving]) -> [WishSaving] {
        return savings.sorted { $0.createdAt > $1.createdAt }
    }
}

/// 목표 금액 대비 모은 금액. 목표 금액이 없으면(0) 표시하지 않으므로 nil 이 된다.
struct WishSavingProgress: Equatable, Hashable {
    let savedAmount: Int
    let targetAmount: Int
    /// 금액의 통화(ISO 4217) (GH-103)
    let currency: String

    var isCompleted: Bool {
        savedAmount >= targetAmount
    }

    var remainingAmount: Int {
        max(targetAmount - savedAmount, 0)
    }

    /// 진행 바 비율. 100% 에서 멈춘다 (R-6).
    var ratio: Double {
        min(Double(savedAmount) / Double(targetAmount), 1)
    }

    /// 반올림한 퍼센트. 목표 미만이면 100% 로 보이지 않도록 99 에서 멈춘다 (R-3).
    var percent: Int {
        let rounded = Int((ratio * 100).rounded())
        return isCompleted ? 100 : min(rounded, 99)
    }

    init?(targetAmount: Int, savings: [WishSaving], currency: String = "KRW") {
        guard targetAmount > 0 else { return nil }
        self.targetAmount = targetAmount
        self.currency = currency
        self.savedAmount = savings.reduce(0) { $0 + $1.amount }
    }
}

/// 적금처럼 정한 넣는 주기·한 번 금액 (GH-121). 기록만 하고 실제 돈은 옮기지 않는다 (R-7).
/// 위젯도 `Wish`를 읽어 이 파일을 같이 쓴다
struct SavingPlan: Equatable, Hashable {
    enum Cycle: String, CaseIterable {
        case weekly
        case monthly
    }

    let cycle: Cycle
    /// 매주면 요일(`Calendar` weekday, 1=일요일 … 7=토요일), 매달이면 날짜(1~31)
    let day: Int
    /// 한 번 넣는 금액. 통화의 최소 단위, 0 보다 크다
    let amount: Int

    /// 값이 어긋나면(날 범위 밖·금액 0 이하) 계획을 만들지 않는다 (R-8)
    init?(cycle: Cycle, day: Int, amount: Int) {
        guard amount > 0, amount <= WishSaving.maxAmount, Self.dayRange(cycle).contains(day) else { return nil }
        self.cycle = cycle
        self.day = day
        self.amount = amount
    }

    /// 저장한 컬럼 값(`savingPlanCycle`·`savingPlanDay`·`savingPlanAmount`)에서 읽는다. ""·0 이면 계획 없음
    init?(storedCycle: String, day: Int, amount: Int) {
        guard let cycle = Cycle(rawValue: storedCycle) else { return nil }
        self.init(cycle: cycle, day: day, amount: amount)
    }

    static func dayRange(_ cycle: Cycle) -> ClosedRange<Int> {
        switch cycle {
        case .weekly:
            return 1...7
        case .monthly:
            return 1...31
        }
    }
}
