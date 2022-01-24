import Foundation

struct Wish: Equatable {
    let id: String
    var emoji: String
    var category: Category
    var title: String
    var endDate: Date?
    let finishDate: Date?
    var notifications: [SeepNotification]
    var memo: String
    var hashtags: [String]
    var isSuccess: Bool
    let createdAt: Date
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func deadlineOrder(wish1: Wish, wish2: Wish) -> Bool {
        // TODO: 정렬 순서 나오면 계산 필요
        return true
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
        emoji: String = "",
        category: Category = .wantToDo,
        title: String = "",
        endDate: Date? = nil,
        finishDate: Date? = nil,
        notifications: [SeepNotification] = [],
        memo: String = "",
        hashtags: [String] = [],
        isSuccess: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = UUID().uuidString
        self.emoji = emoji
        self.category = category
        self.title = title
        self.endDate = endDate
        self.finishDate = finishDate
        self.notifications = notifications
        self.memo = memo
        self.hashtags = hashtags
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
        self.memo = dto.memo
        self.hashtags = Array(dto.hashtag)
        self.isSuccess = dto.isSuccess
        self.createdAt = dto.createdAt
    }
}
