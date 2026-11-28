import Foundation

/// "근처에 가면 알려줘요"의 권한·개수·예약·다시 걸기 (GH-126 R-3, R-5, R-6). ViewModel 은 이 protocol 만 안다 (R2)
protocol NearbyAlertSchedulerProtocol: AnyObject {
    /// 켜 둔 근처 알림이 한도(10개)에 닿았는지. `wishId` 위시는 빼고 센다 (R-6)
    func isAtLimit(excluding wishId: String) -> Bool
    /// 켜기 전에: 알림 → 위치(앱 사용 중) 순서로, 미결정이면 묻는다. 둘 다 허용이면 true (R-3)
    func requestAuthorization() async -> Bool
    /// 걸 수 있는 위시면 (다시) 예약하고, 아니면 예약을 지운다. 권한이 없으면 묻지 않고 건너뛴다
    func schedule(wish: Wish) async
    func cancel(wishId: String)
    /// 앱이 활성화될 때: 켜진 위시 중 예약이 없는 것만 다시 걸고, 켜진 위시에 없는 근처 알림은 지운다 (R-5)
    func rescheduleMissing() async
}

final class NearbyAlertScheduler: NearbyAlertSchedulerProtocol {
    /// iOS 지역 모니터링 20개·대기 알림 64개 한도에서 D-day 알림 몫을 남긴다 (R-6)
    static let maxCount = 10

    static let shared = NearbyAlertScheduler()

    private let center: NearbyAlertCenter
    private let wishRepository: WishRepository

    init(center: NearbyAlertCenter = SystemNearbyAlertCenter(), wishRepository: WishRepository = WishRepositoryImpl()) {
        self.center = center
        self.wishRepository = wishRepository
    }

    func isAtLimit(excluding wishId: String) -> Bool {
        wishRepository.fetchNearbyAlertWishes().filter { $0.id != wishId }.count >= Self.maxCount
    }

    func requestAuthorization() async -> Bool {
        var notification = await center.notificationAuthorization()
        if notification == .notDetermined {
            notification = await center.requestNotificationAuthorization()
        }
        // 알림을 받을 수 없으면 위치 권한까지 묻지 않는다
        guard notification == .authorized else { return false }

        var location = await center.locationAuthorization()
        if location == .notDetermined {
            location = await center.requestLocationAuthorization()
        }
        return location == .authorized
    }

    func schedule(wish: Wish) async {
        guard let request = NearbyAlertRequest(wish: wish) else {
            cancel(wishId: wish.id)
            return
        }
        // 다른 기기에서 켠 위시를 받았을 때 등, 이 기기에 권한이 없으면 예약하지 않는다 (서버 저장 절)
        guard await hasAuthorization() else { return }
        center.add(request)
    }

    func cancel(wishId: String) {
        center.remove(identifiers: [NearbyAlertRequest.identifier(wishId: wishId)])
    }

    func rescheduleMissing() async {
        let requests = wishRepository.fetchNearbyAlertWishes().compactMap(NearbyAlertRequest.init(wish:))
        let pending = Set(await center.pendingNearbyIdentifiers())
        let wanted = Set(requests.map(\.identifier))
        // 다른 기기에서 끄거나 지운 위시의 예약이 남았으면 지운다
        center.remove(identifiers: pending.subtracting(wanted).sorted())

        let missing = requests.filter { !pending.contains($0.identifier) }
        guard !missing.isEmpty, await hasAuthorization() else { return }
        missing.forEach(center.add)
    }

    private func hasAuthorization() async -> Bool {
        guard await center.notificationAuthorization() == .authorized else { return false }
        return await center.locationAuthorization() == .authorized
    }
}
