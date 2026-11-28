import Foundation

/// 근처 알림 한 건 (GH-126 R-4). 위시에서 만들고, `NearbyAlertCenter`가 지역 알림으로 예약한다.
/// 들어올 때만·반복 없음은 `SystemNearbyAlertCenter`가 고정으로 건다 — 한 번 울리면 앱을 열 때 다시 건다 (R-5)
struct NearbyAlertRequest: Equatable {
    static let identifierPrefix = "nearby-"
    /// 반경 300m (R-4)
    static let radius: Double = 300

    let identifier: String
    let title: String
    let body: String
    let latitude: Double
    let longitude: Double
    let radius: Double

    /// 근처 알림을 걸 수 있는 위시면 만든다. 켜지 않았거나, 이뤘거나, 가고 싶어요가 아니거나, 장소가 없으면 nil
    init?(wish: Wish) {
        guard wish.nearbyAlertOn, !wish.isSuccess, wish.category == .wantToGo, let place = wish.place else { return nil }
        self.identifier = Self.identifier(wishId: wish.id)
        self.title = Strings.notificationTitle
        self.body = Strings.NearbyAlert.bodyFormat(wish.emoji, wish.title)
            .trimmingCharacters(in: .whitespaces)
        self.latitude = place.latitude
        self.longitude = place.longitude
        self.radius = Self.radius
    }

    static func identifier(wishId: String) -> String {
        identifierPrefix + wishId
    }

    /// `nearby-{wishId}` 이면 위시 id, 아니면(D-day 알림 등) nil
    static func wishId(fromIdentifier identifier: String) -> String? {
        guard identifier.hasPrefix(identifierPrefix) else { return nil }
        let wishId = String(identifier.dropFirst(identifierPrefix.count))
        return wishId.isEmpty ? nil : wishId
    }
}
