import Foundation

/// 홈 정렬. rawValue 는 저장(`Preference.homeSortOrder`)과 `sort_order` 로그의 `type`에 쓴다 (GH-73 R-2, TC-9)
enum HomeSortOrder: String, CaseIterable {
    /// 완료일 가까운 순서
    case deadlineOrder = "deadline"
    
    /// 최근 생성순
    case latestOrder = "latest"

    /// 내가 정한 순서 — 끌어서 바꾼다 (GH-73)
    case manualOrder = "manual"
}

extension HomeSortOrder {
    var title: String {
        switch self {
        case .deadlineOrder:
            Strings.Home.Filter.Sort.deadline
        case .latestOrder:
            Strings.Home.Filter.Sort.latest
        case .manualOrder:
            Strings.Home.Filter.Sort.manual
        }
    }
    
    /// 고정된 위시를 맨 위에(고정 시각 최신순) 두고, 나머지는 이 정렬 기준을 따른다 (GH-33 R-4)
    func sorted(_ wishes: [Wish]) -> [Wish] {
        let pinned = wishes
            .filter { $0.isPinned }
            .sorted { ($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) }
        let others = wishes
            .filter { !$0.isPinned }
            .sorted(by: orderFunction())
        return pinned + others
    }
    
    func orderFunction() -> ((Wish, Wish) -> Bool) {
        switch self {
        case .deadlineOrder:
            return deadlineOrder(wish1:wish2:)
        case .latestOrder:
            return newestOrder(wish1:wish2:)
        case .manualOrder:
            return manualOrder(wish1:wish2:)
        }
    }
    
    private func deadlineOrder(wish1: Wish, wish2: Wish) -> Bool {
        if let endDate1 = wish1.endDate,
           let endDate2 = wish2.endDate {
            return endDate1 < endDate2
        } else {
            if wish1.endDate == nil && wish2.endDate == nil {
                return true
            } else if wish1.endDate == nil && wish2.endDate != nil {
                return false
            } else {
                return true
            }
        }
    }
    
    private func newestOrder(wish1: Wish, wish2: Wish) -> Bool {
        return wish1.createdAt > wish2.createdAt
    }

    /// 순서 값이 작을수록 위. 같으면 최근 생성순 (UNIQUE 제약이 없어 같을 수 있다)
    private func manualOrder(wish1: Wish, wish2: Wish) -> Bool {
        if wish1.manualOrder != wish2.manualOrder {
            return wish1.manualOrder < wish2.manualOrder
        }
        return newestOrder(wish1: wish1, wish2: wish2)
    }
}
