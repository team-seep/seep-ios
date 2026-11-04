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
