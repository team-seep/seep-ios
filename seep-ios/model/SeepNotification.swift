import Foundation

import RealmSwift

class SeepNotification: Object {
    @objc dynamic var type: String
    @objc dynamic var time: Date
    
    var notificationType: NotificationType {
        get {
            return NotificationType(rawValue: self.type) ?? .targetDay
        }
        set {
            self.type = newValue.rawValue
        }
    }
    
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
                return "notification_type_targat_day".localized
                
            case .dayAgo:
                return "notification_type_before_day".localized
                
            case .twoDayAgo:
                return "notification_type_before_two_day".localized
                
            case .weekAgo:
                return "notification_type_before_week".localized
                
            case .everyDay:
                return "notification_type_everyday".localized
            }
        }
    }
}
