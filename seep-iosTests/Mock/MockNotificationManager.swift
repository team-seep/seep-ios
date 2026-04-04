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
}
