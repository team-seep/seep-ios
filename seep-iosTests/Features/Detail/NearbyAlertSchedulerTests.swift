import CoreLocation
import XCTest

@testable import seep_ios

/// 근처 알림 스케줄러 — 권한·한도·예약 내용·다시 걸기 (GH-126 R-3 ~ R-7). 시스템(알림 센터·위치)은 목
final class NearbyAlertSchedulerTests: ViewModelTestCase {
    private var center: MockNearbyAlertCenter!
    private var repository: MockWishRepository!
    private var sut: NearbyAlertScheduler!

    private let place = WishPlace(name: "블루보틀 성수 카페", address: "서울 성동구 아차산로 7", latitude: 37.5478, longitude: 127.0451)

    override func setUp() {
        super.setUp()
        center = MockNearbyAlertCenter()
        repository = MockWishRepository()
        sut = NearbyAlertScheduler(center: center, wishRepository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        center = nil
        super.tearDown()
    }

    private func onWish(_ id: String, emoji: String = "☕️", title: String = "성수 블루보틀에서 아침 커피") -> Wish {
        Wish(id: id, emoji: emoji, category: .wantToGo, title: title, place: place, nearbyAlertOn: true)
    }

    // MARK: GH-126 TC3

    func test_GH126_TC3_켠위시를예약하면_nearby식별자로_반경300m_한건이걸린다() async {
        // Given
        let wish = onWish("wish-1")

        // When
        await sut.schedule(wish: wish)

        // Then
        XCTAssertEqual(center.addedRequests.count, 1)
        let request = center.addedRequests.first
        XCTAssertEqual(request?.identifier, "nearby-wish-1")
        XCTAssertEqual(request?.radius, 300)
        XCTAssertEqual(request?.latitude, place.latitude)
        XCTAssertEqual(request?.longitude, place.longitude)
        XCTAssertEqual(request?.title, Strings.notificationTitle)
        XCTAssertEqual(request?.body, "☕️ 성수 블루보틀에서 아침 커피\n근처에 왔어요. 지금 들러 볼까요?")
    }

    func test_GH126_TC3_이모지가없으면_본문이제목으로시작한다() {
        // Given
        let wish = onWish("wish-1", emoji: "")

        // When
        let request = NearbyAlertRequest(wish: wish)

        // Then
        XCTAssertEqual(request?.body, "성수 블루보틀에서 아침 커피\n근처에 왔어요. 지금 들러 볼까요?")
    }

    func test_GH126_TC3_끄거나이뤘거나장소가없는위시는_예약대신지운다() async {
        // Given
        var off = onWish("off"); off.nearbyAlertOn = false
        var finished = onWish("finished"); finished.isSuccess = true
        var noPlace = onWish("no-place"); noPlace.place = nil

        // When
        for wish in [off, finished, noPlace] {
            await sut.schedule(wish: wish)
        }

        // Then
        XCTAssertTrue(center.addedRequests.isEmpty)
        XCTAssertEqual(center.removedIdentifiers, ["nearby-off", "nearby-finished", "nearby-no-place"])
    }

    func test_GH126_TC3_식별자에서위시id를읽고_D_day알림식별자는무시한다() {
        // Given / When / Then
        XCTAssertEqual(NearbyAlertRequest.wishId(fromIdentifier: "nearby-wish-1"), "wish-1")
        XCTAssertNil(NearbyAlertRequest.wishId(fromIdentifier: "6F1C-notification-id"))
        XCTAssertNil(NearbyAlertRequest.wishId(fromIdentifier: "nearby-"))
    }

    // MARK: GH-126 TC4

    func test_GH126_TC4_알림위치모두미결정이면_알림다음위치순서로묻고_둘다허용이면true() async {
        // Given
        center.notificationStatus = .notDetermined
        center.locationStatus = .notDetermined

        // When
        let isGranted = await sut.requestAuthorization()

        // Then
        XCTAssertTrue(isGranted)
        XCTAssertEqual(center.requestedPermissions, ["notification", "location"])
    }

    func test_GH126_TC4_위치를거부하면_false() async {
        // Given
        center.locationStatus = .notDetermined
        center.locationAnswer = .denied

        // When
        let isGranted = await sut.requestAuthorization()

        // Then
        XCTAssertFalse(isGranted)
        XCTAssertEqual(center.requestedPermissions, ["location"])
    }

    func test_GH126_TC4_알림이거부돼있으면_위치는묻지않고_false() async {
        // Given
        center.notificationStatus = .denied
        center.locationStatus = .notDetermined

        // When
        let isGranted = await sut.requestAuthorization()

        // Then
        XCTAssertFalse(isGranted)
        XCTAssertTrue(center.requestedPermissions.isEmpty)
    }

    func test_GH126_TC4_이미허용돼있으면_팝업없이true() async {
        // Given: 기본값 둘 다 허용

        // When
        let isGranted = await sut.requestAuthorization()

        // Then
        XCTAssertTrue(isGranted)
        XCTAssertTrue(center.requestedPermissions.isEmpty)
    }

    func test_GH126_TC4_정확한위치를끄고허용하면_거부로본다() {
        // Given / When / Then: 대략적 위치에서는 iOS 가 지역 감시를 하지 않는다
        XCTAssertEqual(SystemNearbyAlertCenter.locationAuthorization(.authorizedWhenInUse, accuracy: .reducedAccuracy), .denied)
        XCTAssertEqual(SystemNearbyAlertCenter.locationAuthorization(.authorizedWhenInUse, accuracy: .fullAccuracy), .authorized)
        XCTAssertEqual(SystemNearbyAlertCenter.locationAuthorization(.denied, accuracy: .fullAccuracy), .denied)
        XCTAssertEqual(SystemNearbyAlertCenter.locationAuthorization(.notDetermined, accuracy: .reducedAccuracy), .notDetermined)
    }

    // MARK: GH-126 TC5

    func test_GH126_TC5_켠위시가10개면_한도이고_9개거나그위시자신을빼면아니다() {
        // Given
        repository.fetchNearbyAlertWishesResult = (1...10).map { onWish("w\($0)") }

        // When / Then
        XCTAssertTrue(sut.isAtLimit(excluding: "new"))
        XCTAssertFalse(sut.isAtLimit(excluding: "w3"))

        repository.fetchNearbyAlertWishesResult = (1...9).map { onWish("w\($0)") }
        XCTAssertFalse(sut.isAtLimit(excluding: "new"))
    }

    // MARK: GH-126 TC6

    func test_GH126_TC6_위시알림을취소하면_근처알림예약도지운다() {
        // Given: 앱의 D-day 알림 관리자. 완료·삭제는 모든 경로가 이 메서드를 부른다
        let scheduler = MockNearbyAlertScheduler()
        let notificationManager = NotificationManager(nearbyAlertScheduler: scheduler)

        // When
        notificationManager.cancelNotifications(wish: onWish("wish-1"))

        // Then
        XCTAssertEqual(scheduler.cancelledWishIds, ["wish-1"])
    }

    func test_GH126_TC6_권한을확인하는사이취소되면_예약하지않는다() async {
        // Given: 예약이 권한 확인을 기다리는 동안 위시를 완료·삭제해 취소가 먼저 끝난다
        center.onNotificationAuthorizationCheck = { [unowned self] in
            sut.cancel(wishId: "wish-1")
        }

        // When
        await sut.schedule(wish: onWish("wish-1"))

        // Then
        XCTAssertTrue(center.addedRequests.isEmpty)
        XCTAssertNil(center.pending["nearby-wish-1"])
    }

    func test_GH126_TC6_예약을맡긴뒤시작전에취소되면_걸지않는다() async {
        // Given: 예약을 Task 로 맡긴 때의 취소 횟수. Task 가 시작되기 전에 완료·삭제로 취소됐다
        let cancelCount = sut.cancelCount(wishId: "wish-1")
        sut.cancel(wishId: "wish-1")

        // When
        await sut.schedule(wish: onWish("wish-1"), cancelCount: cancelCount)

        // Then
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func test_GH126_TC6_위시알림을예약하면_맡긴때의취소횟수를넘긴다() {
        // Given
        let scheduler = MockNearbyAlertScheduler()
        scheduler.cancelCountResult = 7
        let notificationManager = NotificationManager(nearbyAlertScheduler: scheduler)

        // When
        notificationManager.reserveNotifications(wish: onWish("wish-1"))
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        // Then
        XCTAssertEqual(scheduler.scheduledCancelCounts, [7])
    }

    func test_GH126_TC6_다시거는사이취소된위시는_빼고건다() async {
        // Given
        repository.fetchNearbyAlertWishesResult = [onWish("wish-1"), onWish("wish-2")]
        center.onNotificationAuthorizationCheck = { [unowned self] in
            sut.cancel(wishId: "wish-1")
        }

        // When
        await sut.rescheduleMissing()

        // Then
        XCTAssertEqual(center.addedRequests.map(\.identifier), ["nearby-wish-2"])
    }

    func test_GH126_TC6_켜지않은위시를예약하면_근처알림은걸지않는다() {
        // Given
        let scheduler = MockNearbyAlertScheduler()
        let notificationManager = NotificationManager(nearbyAlertScheduler: scheduler)
        var wish = onWish("wish-1")
        wish.nearbyAlertOn = false

        // When
        notificationManager.reserveNotifications(wish: wish)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        // Then
        XCTAssertTrue(scheduler.scheduledWishes.isEmpty)
    }

    // MARK: GH-126 TC8

    func test_GH126_TC8_켜진3개중1개만예약이남았으면_앱활성화때_나머지2개만다시건다() async throws {
        // Given
        repository.fetchNearbyAlertWishesResult = [onWish("a"), onWish("b"), onWish("c")]
        center.seedPending(try XCTUnwrap(NearbyAlertRequest(wish: onWish("b"))))

        // When
        await sut.rescheduleMissing()

        // Then
        XCTAssertEqual(center.addedRequests.map(\.identifier).sorted(), ["nearby-a", "nearby-c"])
        XCTAssertEqual(Set(center.pending.keys), ["nearby-a", "nearby-b", "nearby-c"])
    }

    func test_GH126_TC8_권한이없으면_다시걸지않는다() async {
        // Given
        repository.fetchNearbyAlertWishesResult = [onWish("a"), onWish("b")]
        center.locationStatus = .denied

        // When
        await sut.rescheduleMissing()

        // Then
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func test_GH126_TC8_켜진위시에없는근처알림이남아있으면_지운다() async throws {
        // Given: 다른 기기에서 끈 위시의 예약이 남아 있다
        repository.fetchNearbyAlertWishesResult = [onWish("a")]
        center.seedPending(try XCTUnwrap(NearbyAlertRequest(wish: onWish("a"))))
        center.seedPending(try XCTUnwrap(NearbyAlertRequest(wish: onWish("turned-off"))))

        // When
        await sut.rescheduleMissing()

        // Then
        XCTAssertEqual(center.removedIdentifiers, ["nearby-turned-off"])
        XCTAssertTrue(center.addedRequests.isEmpty)
        XCTAssertEqual(Set(center.pending.keys), ["nearby-a"])
    }
}
