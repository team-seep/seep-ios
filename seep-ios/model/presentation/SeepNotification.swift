import Foundation

struct SeepNotification: Equatable {
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
    
    var type: NotificationType
    var time: Date
    
    init(
        type: NotificationType = .targetDay,
        time: Date = Calendar.current.date(
            bySettingHour: 11,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    ) {
        self.type = type
        self.time = time
    }
}
