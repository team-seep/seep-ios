import Foundation

import RealmSwift

class SeepNotification: Object {
    @objc dynamic var type: String
    @objc dynamic var time: Date
    
    init(
        type: NotificationType = .targetDay,
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
        self.type = NotificationType.targetDay.rawValue
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
        
        var toString: String {
            switch self {
            case .targetDay:
                return "당일"
                
            case .dayAgo:
                return "1일 전"
                
            case .twoDayAgo:
                return "2일 전"
                
            case .weekAgo:
                return "일주일 전"
                
            case .everyDay:
                return "매일"
            }
        }
    }
}
