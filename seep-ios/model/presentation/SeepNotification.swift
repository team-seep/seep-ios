import Foundation

struct SeepNotification: Equatable, Hashable {
    enum NotificationType: String {
        case targetDay
        case dayAgo
        case twoDayAgo
        case weekAgo
        case everyDay
    }
    
    var id = UUID().uuidString
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
    
    init(dto: NotificationDTO) {
        // 예약할 때 쓴 id 를 그대로 써야 완료·삭제 때 대기 중 알림을 지울 수 있다 (GH-48 에서 발견)
        self.id = dto.id
        self.type = NotificationType(rawValue: dto.type) ?? .targetDay
        self.time = dto.time
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.type == rhs.type && lhs.time == rhs.time
    }
}
