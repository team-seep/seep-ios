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
    /// 완료 소감 한 줄. 비어 있으면 소감 없음 (GH-25)
    var finishNote: String
    /// 홈 맨 위에 고정한 시각. nil 이면 고정 아님 (GH-33)
    var pinnedAt: Date?
    /// 상품 링크(http/https). 비어 있으면 링크 없음 (GH-29)
    var link: String
    /// 마지막으로 점검(여전히 하고 싶어요·수정 저장)한 시각. nil 이면 점검한 적 없음 (GH-30)
    var lastCheckedAt: Date?
    /// 붙인 장소. 가고 싶어요 위시에서만 입력받는다 (GH-31)
    var place: WishPlace?
    /// 붙인 사진 파일 이름. 비어 있으면 사진 없음 (GH-36)
    var photoFileName: String
    /// "미래의 나에게" 편지(최대 300자). 비어 있으면 편지 없음. 이루기 전에는 보여주지 않는다 (GH-61)
    var futureLetter: String
    /// 편지를 봉인한 시각. 편지가 없으면 nil (GH-61)
    var futureLetterSealedAt: Date?
    /// "내가 정한 순서" 값. 카테고리 안에서 작을수록 위다 (GH-73)
    var manualOrder: Double
    let createdAt: Date
    
    /// 카테고리마다 고정할 수 있는 최대 개수 (GH-33 R-3)
    static let maxPinCountPerCategory = 3
    
    var isPinned: Bool {
        return pinnedAt != nil
    }

    /// 봉인한 편지가 있는지 (GH-61)
    var hasFutureLetter: Bool {
        return !futureLetter.isEmpty
    }
    
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
        finishNote: String = "",
        pinnedAt: Date? = nil,
        link: String = "",
        lastCheckedAt: Date? = nil,
        place: WishPlace? = nil,
        photoFileName: String = "",
        futureLetter: String = "",
        futureLetterSealedAt: Date? = nil,
        manualOrder: Double = 0,
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
        self.finishNote = finishNote
        self.pinnedAt = pinnedAt
        self.link = link
        self.lastCheckedAt = lastCheckedAt
        self.place = place
        self.photoFileName = photoFileName
        self.futureLetter = futureLetter
        self.futureLetterSealedAt = futureLetterSealedAt
        self.manualOrder = manualOrder
        self.createdAt = createdAt
    }
}
