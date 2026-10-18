import Foundation

import RealmSwift

class WishDTO: Object, Identifiable {
    @objc dynamic var _id: String
    @objc dynamic var emoji: String = ""
    @objc dynamic var category: String = ""
    @objc dynamic var title: String = ""
    
    /// 마감 기한
    @objc dynamic var date: Date?
    @objc dynamic var finishDate: Date?
    var notifications = List<NotificationDTO>()
    var steps = List<WishStepDTO>()
    /// 목표 금액(원). 0 이면 저금통 없음 (GH-16 R-8)
    @objc dynamic var targetAmount: Int = 0
    var savings = List<SavingDTO>()
    @objc dynamic var memo: String = ""
    @objc dynamic var hashtag: String = ""
    @objc dynamic var isSuccess: Bool = false
    /// 완료 소감 한 줄(최대 40자). 비어 있으면 소감 없음 (GH-25 R-4)
    @objc dynamic var finishNote: String = ""
    @objc dynamic var createdAt: Date = Date()
    
    
    static func deadlineOrder(wish1: WishDTO, wish2: WishDTO) -> Bool {
        // TODO: 정렬 순서 나오면 계산 필요
        return true
    }
    
    static func finishOrder(wish1: WishDTO, wish2: WishDTO) -> Bool {
        return wish1.finishDate! > wish2.finishDate!
    }
    
    init(wish: Wish) {
        self._id = wish.id
        self.emoji = wish.emoji
        self.category = wish.category.rawValue
        self.title = wish.title
        self.date = wish.endDate
        self.finishDate = wish.finishDate
        
        let notificationDTOs = wish.notifications.map { NotificationDTO(seepNotification: $0) }
        self.notifications.append(objectsIn: notificationDTOs)
        self.steps.append(objectsIn: wish.steps.map(WishStepDTO.init(step:)))
        self.targetAmount = wish.targetAmount
        self.savings.append(objectsIn: wish.savings.map(SavingDTO.init(saving:)))
        self.memo = wish.memo
        self.hashtag = wish.hashtag
        self.isSuccess = wish.isSuccess
        self.finishNote = wish.finishNote
        self.createdAt = wish.createdAt
    }
    
    override init() {
        self._id = UUID().uuidString
    }
}
