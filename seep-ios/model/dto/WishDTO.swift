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
    /// 홈 맨 위에 고정한 시각. nil 이면 고정 아님, 고정끼리는 최신순 (GH-33 R-1)
    @objc dynamic var pinnedAt: Date?
    /// 갖고 싶어요의 상품 링크. 비어 있으면 링크 없음. 썸네일은 저장하지 않는다 (GH-29 R-7)
    @objc dynamic var link: String = ""
    /// "아직 하고 싶어요?"에 답했거나 수정해 저장한 시각. nil 이면 createdAt 을 기준으로 잠든 위시를 판정한다 (GH-30 R-1)
    @objc dynamic var lastCheckedAt: Date?
    /// 붙인 장소 이름. 비어 있으면 장소 없음 (GH-31 R-4)
    @objc dynamic var placeName: String = ""
    @objc dynamic var placeAddress: String = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    /// 붙인 사진 파일 이름(`Application Support/WishPhotos/` 안). 비어 있으면 사진 없음 (GH-36 R-9)
    @objc dynamic var photoFileName: String = ""
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
        self.pinnedAt = wish.pinnedAt
        self.link = wish.link
        self.lastCheckedAt = wish.lastCheckedAt
        self.placeName = wish.place?.name ?? ""
        self.placeAddress = wish.place?.address ?? ""
        self.latitude = wish.place?.latitude ?? 0
        self.longitude = wish.place?.longitude ?? 0
        self.photoFileName = wish.photoFileName
        self.createdAt = wish.createdAt
    }
    
    override init() {
        self._id = UUID().uuidString
    }
}
