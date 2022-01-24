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
    @objc dynamic var memo: String = ""
    var hashtag = List<String>()
    @objc dynamic var isSuccess: Bool = false
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
        self.memo = wish.memo
        
        self.hashtag.append(objectsIn: wish.hashtags)
        self.isSuccess = wish.isSuccess
        self.createdAt = wish.createdAt
    }
    
    override init() {
        self._id = UUID().uuidString
    }
}
