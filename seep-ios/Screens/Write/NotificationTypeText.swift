import Foundation

// SeepNotification 은 위젯 타깃에도 들어가는데 위젯에는 SwiftGen Strings 가 없어서, 화면에 쓰는 문구는 앱 타깃에만 둔다 (GH-76 R-3)
extension SeepNotification.NotificationType {
    var toString: String {
        switch self {
        case .targetDay:
            return Strings.notificationTypeTargatDay

        case .dayAgo:
            return Strings.notificationTypeBeforeDay

        case .twoDayAgo:
            return Strings.notificationTypeBeforeTwoDay

        case .weekAgo:
            return Strings.notificationTypeBeforeWeek

        case .everyDay:
            return Strings.notificationTypeEveryday
        }
    }
}
