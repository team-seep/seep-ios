@testable import seep_ios

final class MockNotificationManager: NotificationManagerProtocol {
    var cancelledWishes: [Wish] = []
    var reservedWishes: [Wish] = []

    func cancelNotifications(wish: Wish) {
        cancelledWishes.append(wish)
    }

    func reserveNotifications(wish: Wish) {
        reservedWishes.append(wish)
    }

    /// 적금 계획 알림을 맞춘 위시 (GH-121)
    private(set) var savingPlanUpdatedWishes: [Wish] = []

    func updateSavingPlanNotification(wish: Wish) {
        savingPlanUpdatedWishes.append(wish)
    }

    var authorizationStatusResult: NotificationAuthorization = .authorized
    private(set) var authorizationStatusCallCount = 0

    func authorizationStatus() async -> NotificationAuthorization {
        authorizationStatusCallCount += 1
        return authorizationStatusResult
    }
}
