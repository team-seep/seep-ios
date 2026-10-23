import Foundation

import RealmSwift

/// "갖고 싶어요" 위시에 모은 돈 기록 한 건. 위시가 지워지면 같이 지워지도록 EmbeddedObject 로 둔다 (GH-16 R-8).
class SavingDTO: EmbeddedObject {
    @objc dynamic var _id: String = UUID().uuidString
    @objc dynamic var amount: Int = 0
    @objc dynamic var createdAt: Date = Date()

    convenience init(saving: WishSaving) {
        self.init()
        self._id = saving.id
        self.amount = saving.amount
        self.createdAt = saving.createdAt
    }
}
