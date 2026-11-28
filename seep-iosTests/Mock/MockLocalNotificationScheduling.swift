import UserNotifications

@testable import seep_ios

/// `NotificationManager`가 넣고 뺀 로컬 알림 요청을 기억한다 (GH-121)
final class MockLocalNotificationScheduling: LocalNotificationScheduling {
    /// 지금 예약돼 있는 요청 (id → 요청). 같은 id 를 다시 넣으면 덮어쓴다(시스템과 같음)
    private(set) var pending: [String: UNNotificationRequest] = [:]
    private(set) var removedIdentifiers: [[String]] = []

    func add(request: UNNotificationRequest) {
        pending[request.identifier] = request
    }

    func removePendingRequests(identifiers: [String]) {
        removedIdentifiers.append(identifiers)
        identifiers.forEach { pending[$0] = nil }
    }

    /// 적금 계획 알림만 (id 가 savingPlan- 으로 시작)
    func savingPlanRequests(wishId: String) -> [UNNotificationRequest] {
        pending.values
            .filter { $0.identifier.hasPrefix("savingPlan-\(wishId)") }
            .sorted { $0.identifier < $1.identifier }
    }
}
