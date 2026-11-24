import Foundation

/// 갖고 싶어요 탭 맨 위 "다 합치면" 카드 (GH-148). 이미 적은 목표 금액·모은 돈을 통화별로 합치기만 한다(환산 없음, R-3)
struct WishTotalSummary: Equatable {
    /// 한 통화의 합계. 펼친 목록의 줄도 이 묶음 안에 남은 금액 큰 순으로 들어 있다 (R-6)
    struct CurrencyGroup: Equatable {
        let currency: String
        /// Σ max(목표 − 모은 돈, 0) (R-2)
        let remainingAmount: Int
        /// Σ min(모은 돈, 목표) — 목표를 넘겨 모은 돈은 더하지 않는다 (R-2, TC-5)
        let savedAmount: Int
        let targetAmount: Int
        let items: [Item]

        var count: Int { items.count }

        /// 진행 막대 비율(모은 돈 합계 ÷ 목표 합계)
        var ratio: Double {
            guard targetAmount > 0 else { return 0 }
            return min(Double(savedAmount) / Double(targetAmount), 1)
        }
    }

    /// 펼친 목록 한 줄 (R-6)
    struct Item: Equatable, Identifiable {
        let id: String
        let emoji: String
        let title: String
        let remainingAmount: Int
        let currency: String

        /// 다 모은 싶은 금액 대신 "다 모았어요" (R-7)
        var isCompleted: Bool { remainingAmount == 0 }
    }

    /// 고른 태그(저장 값). nil 이면 '전체' (R-5)
    let tag: String?
    /// 첫 묶음이 큰 줄, 나머지는 보조 줄 (R-3). 비어 있지 않다
    let groups: [CurrencyGroup]
    /// 목표 금액을 정하지 않아 빠진 미완료 싶 수 (R-4)
    let excludedCount: Int

    var primary: CurrencyGroup { groups[0] }
    var secondaryGroups: ArraySlice<CurrencyGroup> { groups.dropFirst() }
    /// 합계에 들어간 싶 수
    var includedCount: Int { groups.reduce(0) { $0 + $1.count } }

    /// 보이는 목록(태그 필터 적용 후)으로 만든다. 목표 금액이 있는 미완료 싶이 없으면 nil (R-1, TC-2)
    /// - Parameter preferredCurrency: 싶 수가 같은 통화가 있을 때 먼저 둘 통화(앱 언어 기본 통화, R-3)
    static func make(wishes: [Wish], tag: String?, preferredCurrency: String) -> WishTotalSummary? {
        let notFinished = wishes.filter { !$0.isSuccess }
        let targeted = notFinished.filter { $0.targetAmount > 0 }
        guard !targeted.isEmpty else { return nil }

        var currencies: [String] = []
        var itemsByCurrency: [String: [Item]] = [:]
        var savedByCurrency: [String: Int] = [:]
        var targetByCurrency: [String: Int] = [:]
        for wish in targeted {
            let saved = wish.savings.reduce(0) { $0 + $1.amount }
            let currency = wish.currency
            if itemsByCurrency[currency] == nil { currencies.append(currency) }
            itemsByCurrency[currency, default: []].append(Item(
                id: wish.id,
                emoji: wish.emoji,
                title: wish.title,
                remainingAmount: max(wish.targetAmount - saved, 0),
                currency: currency
            ))
            savedByCurrency[currency, default: 0] += min(saved, wish.targetAmount)
            targetByCurrency[currency, default: 0] += wish.targetAmount
        }

        // 싶이 많은 통화 → 앱 언어 기본 통화 → 목록에 먼저 나온 통화 순 (R-3, TC-17)
        let orderedCurrencies = currencies.enumerated().sorted { lhs, rhs in
            let lhsCount = itemsByCurrency[lhs.element]?.count ?? 0
            let rhsCount = itemsByCurrency[rhs.element]?.count ?? 0
            if lhsCount != rhsCount { return lhsCount > rhsCount }
            let lhsPreferred = lhs.element == preferredCurrency
            let rhsPreferred = rhs.element == preferredCurrency
            if lhsPreferred != rhsPreferred { return lhsPreferred }
            return lhs.offset < rhs.offset
        }.map(\.element)

        let groups = orderedCurrencies.map { currency in
            let items = itemsByCurrency[currency] ?? []
            return CurrencyGroup(
                currency: currency,
                remainingAmount: items.reduce(0) { $0 + $1.remainingAmount },
                savedAmount: savedByCurrency[currency] ?? 0,
                targetAmount: targetByCurrency[currency] ?? 0,
                // 남은 금액이 큰 순. 같으면 목록 순서 그대로 (R-6)
                items: items.enumerated().sorted { lhs, rhs in
                    lhs.element.remainingAmount != rhs.element.remainingAmount
                        ? lhs.element.remainingAmount > rhs.element.remainingAmount
                        : lhs.offset < rhs.offset
                }.map(\.element)
            )
        }
        return WishTotalSummary(tag: tag, groups: groups, excludedCount: notFinished.count - targeted.count)
    }
}
