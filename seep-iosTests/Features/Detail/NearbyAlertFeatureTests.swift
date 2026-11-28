import XCTest

@testable import seep_ios

/// 상세 장소 섹션 "근처에 가면 알려줘요" 토글 (GH-126 R-2 ~ R-7). 스케줄러·저장소는 목
final class NearbyAlertFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private var scheduler: MockNearbyAlertScheduler!

    private let place = WishPlace(name: "블루보틀 성수 카페", address: "서울 성동구 아차산로 7", latitude: 37.5478, longitude: 127.0451)
    private let newPlace = WishPlace(name: "을지면옥", address: "서울 중구 충무로14길 2-1", latitude: 37.5663, longitude: 126.9918)

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        scheduler = MockNearbyAlertScheduler()
    }

    override func tearDown() {
        repository = nil
        scheduler = nil
        super.tearDown()
    }

    private func makeWish(place: WishPlace?, nearbyAlertOn: Bool = false, isSuccess: Bool = false) -> Wish {
        Wish(id: "wish-1", emoji: "☕️", category: .wantToGo, title: "성수 블루보틀에서 아침 커피", isSuccess: isSuccess, place: place, nearbyAlertOn: nearbyAlertOn)
    }

    private func makeViewModel(wish: Wish, isEditable: Bool = true) -> DetailPlaceViewModel {
        repository.fetchWishResult = [wish]
        return DetailPlaceViewModel(
            config: .init(wish: wish, isNearbyAlertEditable: isEditable),
            dependency: .init(wishRepository: repository, nearbyAlertScheduler: scheduler, logManager: logManager)
        )
    }

    private func nearbyAlertClicks() -> [any LogEventType] {
        clickEvents(objectId: .nearbyAlert)
    }

    // MARK: GH-126 TC1

    func test_GH126_TC1_장소있는가고싶어요위시를홈에서열면_근처알림토글이보이고_꺼져있다() {
        // Given
        let wish = makeWish(place: place)

        // When
        let viewModel = makeViewModel(wish: wish)

        // Then
        XCTAssertTrue(DetailSectionBuilder.sections(for: wish).contains(.place))
        XCTAssertTrue(viewModel.isNearbyAlertVisible)
        XCTAssertFalse(viewModel.state.isNearbyAlertOn)
    }

    func test_GH126_TC1_이미켜둔위시면_토글이켜진채로보인다() {
        // Given
        let wish = makeWish(place: place, nearbyAlertOn: true)

        // When
        let viewModel = makeViewModel(wish: wish)

        // Then
        XCTAssertTrue(viewModel.isNearbyAlertVisible)
        XCTAssertTrue(viewModel.state.isNearbyAlertOn)
    }

    // MARK: GH-126 TC2

    func test_GH126_TC2_장소없는위시면_토글이보이지않는다() {
        // Given
        let wish = makeWish(place: nil)

        // When
        let viewModel = makeViewModel(wish: wish)

        // Then
        XCTAssertFalse(viewModel.isNearbyAlertVisible)
    }

    func test_GH126_TC2_완료목록에서연상세나_이룬위시면_토글이보이지않는다() {
        // Given / When
        let fromFinished = makeViewModel(wish: makeWish(place: place), isEditable: false)
        let finished = makeViewModel(wish: makeWish(place: place, isSuccess: true))

        // Then
        XCTAssertFalse(fromFinished.isNearbyAlertVisible)
        XCTAssertFalse(finished.isNearbyAlertVisible)
    }

    func test_GH126_TC2_장소를지우면_토글이사라진다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place))
        XCTAssertTrue(viewModel.isNearbyAlertVisible)

        // When
        viewModel.send(.tapDelete)

        // Then
        XCTAssertFalse(viewModel.isNearbyAlertVisible)
    }

    // MARK: GH-126 TC3

    func test_GH126_TC3_권한이허용되면_켬이저장되고_스케줄러에1건예약된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place))
        var updates: [Bool] = []
        viewModel.onNearbyAlertUpdate = { updates.append($0) }

        // When
        viewModel.send(.toggleNearbyAlert(true))

        // Then
        waitUntil { self.scheduler.scheduledWishes.count == 1 }
        XCTAssertEqual(scheduler.requestAuthorizationCallCount, 1)
        XCTAssertEqual(repository.updateNearbyAlertCalls.map(\.isOn), [true])
        XCTAssertEqual(repository.updateNearbyAlertCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(scheduler.scheduledWishes.first?.id, "wish-1")
        XCTAssertEqual(scheduler.scheduledWishes.first?.nearbyAlertOn, true)
        XCTAssertEqual(scheduler.scheduledWishes.first?.place, place)
        XCTAssertTrue(viewModel.state.isNearbyAlertOn)
        XCTAssertEqual(updates, [true])
        XCTAssertNil(viewModel.route)
    }

    func test_GH126_TC3_켠토글을끄면_끔이저장되고_예약이지워진다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place, nearbyAlertOn: true))

        // When
        viewModel.send(.toggleNearbyAlert(false))

        // Then
        XCTAssertEqual(repository.updateNearbyAlertCalls.map(\.isOn), [false])
        XCTAssertEqual(scheduler.cancelledWishIds, ["wish-1"])
        XCTAssertFalse(viewModel.state.isNearbyAlertOn)
        XCTAssertEqual(scheduler.requestAuthorizationCallCount, 0)
    }

    // MARK: GH-126 TC4

    func test_GH126_TC4_권한이거부되면_저장되지않고_토글은꺼진채_권한알럿route가온다() {
        // Given
        scheduler.requestAuthorizationResult = false
        let viewModel = makeViewModel(wish: makeWish(place: place))

        // When
        viewModel.send(.toggleNearbyAlert(true))

        // Then
        waitUntil { viewModel.route == .nearbyAlertPermissionAlert }
        XCTAssertTrue(repository.updateNearbyAlertCalls.isEmpty)
        XCTAssertTrue(scheduler.scheduledWishes.isEmpty)
        XCTAssertFalse(viewModel.state.isNearbyAlertOn)
    }

    // MARK: GH-126 TC5

    func test_GH126_TC5_10개가켜져있으면_권한도묻지않고_저장예약없이_한도토스트가뜬다() {
        // Given
        scheduler.isAtLimitResult = true
        let viewModel = makeViewModel(wish: makeWish(place: place))

        // When
        viewModel.send(.toggleNearbyAlert(true))

        // Then
        XCTAssertEqual(viewModel.route, .toast("근처 알림은 10개까지 켤 수 있어요"))
        XCTAssertEqual(scheduler.isAtLimitCalledIds, ["wish-1"])
        XCTAssertEqual(scheduler.requestAuthorizationCallCount, 0)
        XCTAssertTrue(repository.updateNearbyAlertCalls.isEmpty)
        XCTAssertTrue(scheduler.scheduledWishes.isEmpty)
        XCTAssertFalse(viewModel.state.isNearbyAlertOn)
    }

    func test_GH126_TC5_권한팝업사이한도가차면_저장예약없이_한도토스트가뜬다() {
        // Given: 누를 때는 9개였는데, 팝업이 떠 있는 동안 다른 화면·동기화로 10개가 찼다
        scheduler.isAtLimitSequence = [false, true]
        let viewModel = makeViewModel(wish: makeWish(place: place))

        // When
        viewModel.send(.toggleNearbyAlert(true))

        // Then
        waitUntil { viewModel.route != nil }
        XCTAssertEqual(viewModel.route, .toast("근처 알림은 10개까지 켤 수 있어요"))
        XCTAssertEqual(scheduler.requestAuthorizationCallCount, 1)
        XCTAssertTrue(repository.updateNearbyAlertCalls.isEmpty)
        XCTAssertTrue(scheduler.scheduledWishes.isEmpty)
        XCTAssertFalse(viewModel.state.isNearbyAlertOn)
    }

    // MARK: GH-126 TC6

    func test_GH126_TC6_근처알림켠위시의장소를지우면_토글이꺼지고_예약이지워진다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place, nearbyAlertOn: true))
        var updates: [Bool] = []
        viewModel.onNearbyAlertUpdate = { updates.append($0) }

        // When
        viewModel.send(.tapDelete)

        // Then
        XCTAssertFalse(viewModel.state.isNearbyAlertOn)
        XCTAssertEqual(scheduler.cancelledWishIds, ["wish-1"])
        XCTAssertTrue(scheduler.scheduledWishes.isEmpty)
        XCTAssertEqual(updates, [false])
    }

    // MARK: GH-126 TC7

    func test_GH126_TC7_근처알림켠위시의장소를바꾸면_새좌표로다시예약한다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place, nearbyAlertOn: true))

        // When
        viewModel.send(.selectPlace(newPlace))

        // Then
        waitUntil { self.scheduler.scheduledWishes.count == 1 }
        XCTAssertEqual(scheduler.scheduledWishes.first?.id, "wish-1")
        XCTAssertEqual(scheduler.scheduledWishes.first?.place, newPlace)
        XCTAssertTrue(scheduler.cancelledWishIds.isEmpty)
        XCTAssertTrue(viewModel.state.isNearbyAlertOn)
    }

    func test_GH126_TC7_근처알림을켜지않은위시는_장소를바꿔도예약하지않는다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place))

        // When
        viewModel.send(.selectPlace(newPlace))

        // Then
        XCTAssertTrue(scheduler.scheduledWishes.isEmpty)
        XCTAssertFalse(viewModel.state.isNearbyAlertOn)
    }

    // MARK: GH-126 TC12

    func test_GH126_TC12_토글을켜면_nearby_alert클릭로그가_enabled_true로1건전송된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place))

        // When
        viewModel.send(.toggleNearbyAlert(true))
        waitUntil { self.scheduler.scheduledWishes.count == 1 }

        // Then
        let clicks = nearbyAlertClicks()
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .wishDetail)
        XCTAssertEqual(clicks.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(clicks.first?.extraParameters?[.enabled] as? Bool, true)
    }

    func test_GH126_TC12_토글을끄면_nearby_alert클릭로그가_enabled_false로1건전송된다() {
        // Given
        let viewModel = makeViewModel(wish: makeWish(place: place, nearbyAlertOn: true))

        // When
        viewModel.send(.toggleNearbyAlert(false))

        // Then
        let clicks = nearbyAlertClicks()
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.extraParameters?[.enabled] as? Bool, false)
    }

    func test_GH126_TC12_권한거부로켜지못해도_클릭로그는1건전송된다() {
        // Given
        scheduler.requestAuthorizationResult = false
        let viewModel = makeViewModel(wish: makeWish(place: place))

        // When
        viewModel.send(.toggleNearbyAlert(true))
        waitUntil { viewModel.route == .nearbyAlertPermissionAlert }

        // Then
        XCTAssertEqual(nearbyAlertClicks().count, 1)
    }

    func test_GH126_TC12_한도토스트가뜨면_클릭1건과_nearby_alert_limit_toast노출로그가1건전송된다() {
        // Given
        scheduler.isAtLimitResult = true
        let viewModel = makeViewModel(wish: makeWish(place: place))

        // When
        viewModel.send(.toggleNearbyAlert(true))

        // Then
        XCTAssertEqual(nearbyAlertClicks().count, 1)
        let impressions = logManager.sentEvents.filter {
            $0.name == .impression && ($0.extraParameters?[.objectId] as? LogObjectId) == .nearbyAlertLimitToast
        }
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .wishDetail)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .banner)
    }
}
