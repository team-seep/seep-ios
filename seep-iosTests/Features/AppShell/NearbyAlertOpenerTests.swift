import XCTest

@testable import seep_ios

private final class StubDeepLinkStore: ReservedDeepLinkStoring {
    var reservedDeepLink = ""
}

/// 근처 알림을 눌러 앱 열기 (GH-126 R-8)
final class NearbyAlertOpenerTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private var deepLinkStore: StubDeepLinkStore!
    private var router: AppRouter!
    private var sut: NearbyAlertOpener!

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
        deepLinkStore = StubDeepLinkStore()
        router = AppRouter(dependency: .init(wishRepository: repository, deepLinkStore: deepLinkStore))
        router.mainDidAppear()
        let router = router!
        sut = NearbyAlertOpener(routerProvider: { router }, logManager: logManager)
    }

    override func tearDown() {
        sut = nil
        router = nil
        deepLinkStore = nil
        repository = nil
        super.tearDown()
    }

    // MARK: GH-126 TC10

    @MainActor
    func test_GH126_TC10_근처알림을누르면_싶탭에그위시상세를연다() {
        // Given
        repository.fetchWishResult = [Wish(id: "w1", category: .wantToGo, title: "성수 블루보틀")]
        router.selectedTab = .settings

        // When
        let opened = sut.open(notificationIdentifier: "nearby-w1")

        // Then
        XCTAssertTrue(opened)
        XCTAssertEqual(router.selectedTab, .wish)
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "w1", isFinished: false)])
    }

    @MainActor
    func test_GH126_TC10_그사이위시를이뤘으면_상세대신홈을연다() {
        // Given
        repository.fetchWishResult = [Wish(id: "w1", category: .wantToGo, title: "성수 블루보틀", isSuccess: true)]
        router.selectedTab = .settings

        // When
        sut.open(notificationIdentifier: "nearby-w1")

        // Then
        XCTAssertEqual(router.selectedTab, .wish)
        XCTAssertTrue(router.wishPath.isEmpty)
        XCTAssertTrue(router.finishedPath.isEmpty)
    }

    @MainActor
    func test_GH126_TC10_그사이위시가지워졌으면_홈을연다() {
        // Given
        repository.fetchWishResult = []
        router.selectedTab = .settings

        // When
        sut.open(notificationIdentifier: "nearby-gone")

        // Then
        XCTAssertEqual(router.selectedTab, .wish)
        XCTAssertTrue(router.wishPath.isEmpty)
    }

    @MainActor
    func test_GH126_TC10_메인이뜨기전에누르면_맡아뒀다가메인이뜰때상세를연다() {
        // Given: 냉시작 — 메인 전
        let coldRouter = AppRouter(dependency: .init(wishRepository: repository, deepLinkStore: deepLinkStore))
        let opener = NearbyAlertOpener(routerProvider: { coldRouter }, logManager: logManager)
        repository.fetchWishResult = [Wish(id: "w1", category: .wantToGo, title: "성수 블루보틀")]

        // When
        opener.open(notificationIdentifier: "nearby-w1")
        XCTAssertTrue(coldRouter.wishPath.isEmpty)
        coldRouter.mainDidAppear()

        // Then
        XCTAssertEqual(coldRouter.wishPath, [.wishDetail(id: "w1", isFinished: false)])
    }

    @MainActor
    func test_GH126_TC10_D_day알림을누르면_아무것도하지않는다() {
        // Given
        repository.fetchWishResult = [Wish(id: "w1", title: "서핑")]
        router.selectedTab = .settings

        // When
        let opened = sut.open(notificationIdentifier: "notification-uuid")

        // Then
        XCTAssertFalse(opened)
        XCTAssertEqual(router.selectedTab, .settings)
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    // MARK: GH-126 TC12

    @MainActor
    func test_GH126_TC12_근처알림을눌러앱이열리면_open_nearby_alert이벤트가1건전송된다() {
        // Given
        repository.fetchWishResult = [Wish(id: "w1", category: .wantToGo, title: "성수 블루보틀")]

        // When
        sut.open(notificationIdentifier: "nearby-w1")

        // Then
        let events = logManager.sentEvents.filter { $0.name == .openNearbyAlert }
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .wishDetail)
        XCTAssertEqual(logManager.sentEvents.count, 1)
    }
}
