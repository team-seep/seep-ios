@testable import seep_ios_dev

final class MockNotificationManager: NotificationManagerProtocol {
    var cancelledWishes: [Wish] = []
    var reservedWishes: [Wish] = []

    func cancelNotifications(wish: Wish) {
        cancelledWishes.append(wish)
    }

    func reserveNotifications(wish: Wish) {
        reservedWishes.append(wish)
    }

    var authorizationStatusResult: NotificationAuthorization = .authorized
    private(set) var authorizationStatusCallCount = 0

    func authorizationStatus() async -> NotificationAuthorization {
        authorizationStatusCallCount += 1
        return authorizationStatusResult
    }
}
