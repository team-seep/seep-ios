import Foundation

import RealmSwift

class NotificationDTO: Object {
    @objc dynamic var id: String
    @objc dynamic var type: String
    @objc dynamic var time: Date
    
    override init() {
        self.id = UUID().uuidString
        self.type = SeepNotification.NotificationType.targetDay.rawValue
        self.time = Calendar.current.date(
            bySettingHour: 11,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }
    
    init(seepNotification: SeepNotification) {
        self.id = seepNotification.id
        self.type = seepNotification.type.rawValue
        self.time = seepNotification.time
    }
}
