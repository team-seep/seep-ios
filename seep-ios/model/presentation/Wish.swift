import Foundation

struct Wish: Equatable, Hashable {
    let id: String
    var emoji: String
    var category: Category
    var title: String
    var endDate: Date?
    var finishDate: Date?
    var notifications: [SeepNotification]
    /// 추가한 순서(order) 오름차순
    var steps: [WishStep]
    /// 목표 금액(원). 0 이면 저금통 없음 (GH-16)
    var targetAmount: Int
    /// 모은 돈 기록, 최신순
    var savings: [WishSaving]
    var memo: String
    var hashtag: String
    var isSuccess: Bool
    let createdAt: Date
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func deadlineOrder(wish1: Wish, wish2: Wish) -> Bool {
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
    
    static func finishOrder(wish1: Wish, wish2: Wish) -> Bool {
        return wish1.finishDate! > wish2.finishDate!
    }
    
    static let mockData: Wish = {
        let wish = Wish(
            emoji: "🤔",
            title: "단양가서 패러글라이딩 하기",
            endDate: Date()
        )
        
        return wish
    }()
    
    init(
        id: String = UUID().uuidString,
        emoji: String = "",
        category: Category = .wantToDo,
        title: String = "",
        endDate: Date? = nil,
        finishDate: Date? = nil,
        notifications: [SeepNotification] = [],
        steps: [WishStep] = [],
        targetAmount: Int = 0,
        savings: [WishSaving] = [],
        memo: String = "",
        hashtag: String = "",
        isSuccess: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.emoji = emoji
        self.category = category
        self.title = title
        self.endDate = endDate
        self.finishDate = finishDate
        self.notifications = notifications
        self.steps = steps
        self.targetAmount = targetAmount
        self.savings = savings
        self.memo = memo
        self.hashtag = hashtag
        self.isSuccess = isSuccess
        self.createdAt = createdAt
    }
    
    init(dto: WishDTO) {
        self.id = dto._id
        self.emoji = dto.emoji
        self.category = Category(rawValue: dto.category) ?? .wantToDo
        self.title = dto.title
        self.endDate = dto.date
        self.finishDate = dto.finishDate
        self.notifications = Array(dto.notifications).map(SeepNotification.init)
        self.steps = Array(dto.steps).map(WishStep.init(dto:)).sorted { $0.order < $1.order }
        self.targetAmount = dto.targetAmount
        self.savings = WishSaving.latestFirst(Array(dto.savings).map(WishSaving.init(dto:)))
        self.memo = dto.memo
        self.hashtag = dto.hashtag
        self.isSuccess = dto.isSuccess
        self.createdAt = dto.createdAt
    }
}
