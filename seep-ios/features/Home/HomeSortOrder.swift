import Foundation

enum HomeSortOrder {
    /// 완료일 가까운 순서
    case deadlineOrder
    
    /// 최근 생성순
    case latestOrder
}

extension HomeSortOrder {
    var title: String {
        switch self {
        case .deadlineOrder:
            Strings.Home.Filter.Sort.deadline
        case .latestOrder:
            Strings.Home.Filter.Sort.latest
        }
    }
    
    func orderFunction() -> ((Wish, Wish) -> Bool) {
        switch self {
        case .deadlineOrder:
            return deadlineOrder(wish1:wish2:)
        case .latestOrder:
            return newestOrder(wish1:wish2:)
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
        return wish1.createdAt < wish2.createdAt
    }
}
