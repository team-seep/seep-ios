import Foundation

import RealmSwift

/// 위시의 단계(체크리스트 한 줄). 위시가 지워지면 같이 지워지도록 EmbeddedObject 로 둔다.
class WishStepDTO: EmbeddedObject {
    @objc dynamic var _id: String = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var isDone: Bool = false
    @objc dynamic var order: Int = 0

    convenience init(step: WishStep) {
        self.init()
        self._id = step.id
        self.title = step.title
        self.isDone = step.isDone
        self.order = step.order
    }
}
