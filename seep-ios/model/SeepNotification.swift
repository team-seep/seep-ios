import Foundation

import RealmSwift

class SeepNotification: Object {
    @objc dynamic var type: String
    @objc dynamic var time: Date
    
    init(
        type: NotificationType = .dayAgo,
        time: Date = Calendar.current.date(
            bySettingHour: 11,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    ) {
        self.type = type.rawValue
        self.time = time
    }
    
    override init() {
        self.type = NotificationType.dayAgo.rawValue
        self.time = Calendar.current.date(
            bySettingHour: 11,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

extension SeepNotification {
    enum NotificationType: String {
        case targetDay
        case dayAgo
        case twoDayAgo
        case weekAgo
        case everyDay
    }
}
