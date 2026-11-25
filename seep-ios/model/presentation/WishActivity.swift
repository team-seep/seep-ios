import Foundation

/// 싶에 다가간 행동 하나. 이룬 싶 탭 잔디가 날짜별로 센다 (GH-146 R-2)
struct WishActivity: Equatable, Identifiable {
    enum Kind: Equatable {
        /// 싶을 담음 (`wish.createdAt`)
        case added
        /// 단계를 체크함 (`wishStep.doneAt`)
        case stepDone(stepTitle: String)
        /// 모은 돈을 기록함 (`wishSaving.createdAt`)
        case saving(amount: Int, currency: String)
        /// 일지를 씀 (`wishJournal.createdAt`)
        case journal
        /// 이룸 (`wish.finishDate`)
        case finished

        /// 모은 돈·이룸은 날짜만 저장한다(자정). 시각을 모르니 그날 시각이 있는 행동 뒤에 둔다 (R-5) —
        /// 같은 날 담고 이룬 위시가 "이뤘어요!"부터 나오지 않게
        var isDateOnly: Bool {
            switch self {
            case .saving, .finished: return true
            case .added, .stepDone, .journal: return false
            }
        }

        /// 같은 자리면 담음 → 단계 → 모은 돈 → 일지 → 이룸 순서로 둔다 (R-5)
        var sortRank: Int {
            switch self {
            case .added: return 0
            case .stepDone: return 1
            case .saving: return 2
            case .journal: return 3
            case .finished: return 4
            }
        }
    }

    /// "{종류}-{줄 id}". 같은 위시의 담음·이룸이 겹치지 않게 종류를 붙인다
    let id: String
    let wishId: String
    let emoji: String
    let wishTitle: String
    /// 위시 상세를 열 때 넘긴다
    let isWishFinished: Bool
    let kind: Kind
    let date: Date

    /// 시간순, 같은 시각이면 종류 순서. 날짜만 아는 행동은 그날 끝에 둔다 (R-5)
    static func chronological(_ lhs: WishActivity, _ rhs: WishActivity) -> Bool {
        if lhs.sortDate != rhs.sortDate { return lhs.sortDate < rhs.sortDate }
        if lhs.kind.sortRank != rhs.kind.sortRank { return lhs.kind.sortRank < rhs.kind.sortRank }
        return lhs.id < rhs.id
    }

    /// 날짜만 저장한 행동(자정)은 그날 마지막 순간으로 본다
    private var sortDate: Date {
        kind.isDateOnly ? date.addingTimeInterval(24 * 60 * 60 - 1) : date
    }
}
