import XCTest

@testable import seep_ios_dev

private final class StubDeepLinkStore: ReservedDeepLinkStoring {
    var reservedDeepLink = ""
}

/// 아이패드 레이아웃: 사이드바·상세 열·위젯 링크·로그 (GH-99)
final class PadLayoutFeatureTests: ViewModelTestCase {
    private var wishRepository: MockWishRepository!
    private var deepLinkStore: StubDeepLinkStore!
    private var router: AppRouter!
    private var sut: PadRootViewModel!

    override func setUp() {
        super.setUp()
        wishRepository = MockWishRepository()
        deepLinkStore = StubDeepLinkStore()
        router = AppRouter(dependency: .init(wishRepository: wishRepository, deepLinkStore: deepLinkStore))
        router.mainDidAppear()
        router.setRegularLayout(true)
        sut = PadRootViewModel(dependency: .init(router: router, wishRepository: wishRepository, logManager: logManager))
    }

    override func tearDown() {
        sut = nil
        router = nil
        deepLinkStore = nil
        wishRepository = nil
        super.tearDown()
    }

    private func url(_ deepLink: WidgetDeepLink) -> URL {
        deepLink.url ?? URL(fileURLWithPath: "/")
    }

    private func impressionEvents(objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter { event in
            event.name == .impression && (event.extraParameters?[.objectId] as? LogObjectId) == objectId
        }
    }

    // MARK: TC-2

    func test_GH99_TC2_사이드바에서_갖고싶어요를누르면_목록이_갖고싶어요로바뀐다() {
        // Given
        wishRepository.fetchNotFinishCountResult = 4
        sut.send(.onAppear(isLandscape: true))

        // When
        sut.send(.tapSidebar(.wantToGet))

        // Then
        XCTAssertEqual(router.padSection, .category(.wantToGet))
        XCTAssertEqual(router.homeCategory, .wantToGet)
        XCTAssertEqual(router.selectedTab, .wish)
        XCTAssertEqual(sut.selectedItem, .wantToGet)
        XCTAssertEqual(sut.state.counts[.wantToGet], 4)
    }

    func test_GH99_TC2_다른항목으로옮기면_보던상세와_쌓인화면을닫는다() {
        // Given
        router.push(.wishDetail(id: "w1", isFinished: false))
        router.push(.search(finishedOnly: false))

        // When
        sut.send(.tapSidebar(.finished))

        // Then
        XCTAssertEqual(router.padSection, .finished)
        XCTAssertEqual(router.selectedTab, .finished)
        XCTAssertNil(router.padSelection)
        XCTAssertTrue(router.wishPath.isEmpty)
    }

    // MARK: TC-3

    func test_GH99_TC3_홈목록에서_위시를누르면_쌓지않고_상세열에연다() {
        // When
        router.push(.wishDetail(id: "w1", isFinished: false))

        // Then
        XCTAssertEqual(router.padSelection, PadWishSelection(id: "w1", isFinished: false))
        XCTAssertTrue(router.wishPath.isEmpty)
    }

    func test_GH99_TC3_이룬싶목록에서_위시를누르면_상세열에_보기전용으로연다() {
        // Given
        sut.send(.tapSidebar(.finished))

        // When
        router.push(.wishDetail(id: "w2", isFinished: true))

        // Then
        XCTAssertEqual(router.padSelection, PadWishSelection(id: "w2", isFinished: true))
        XCTAssertTrue(router.finishedPath.isEmpty)
    }

    func test_GH99_TC3_상세열에서_지우면_상세열이비고_목록은그대로다() {
        // Given
        router.push(.wishDetail(id: "w1", isFinished: false))

        // When
        router.closePadDetail()

        // Then
        XCTAssertNil(router.padSelection)
        XCTAssertEqual(router.padSection, .category(.wantToDo))
    }

    func test_GH99_TC3_아이폰에서는_지금처럼_탭에쌓는다() {
        // Given
        router.setRegularLayout(false)

        // When
        router.push(.wishDetail(id: "w1", isFinished: false))

        // Then
        XCTAssertNil(router.padSelection)
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "w1", isFinished: false)])
    }

    // MARK: TC-4

    func test_GH99_TC4_상세열에서_DB가바뀌면_목록이다시읽도록알린다() {
        // Given
        let before = router.wishesChangedToken

        // When
        wishRepository.simulateChange()

        // Then
        XCTAssertEqual(wishRepository.observeChangesCallCount, 1)
        XCTAssertEqual(router.wishesChangedToken, before + 1)
    }

    func test_GH99_TC4_좁은화면으로바뀌면_DB변경을듣지않는다() {
        // Given
        router.setRegularLayout(false)
        let before = router.wishesChangedToken

        // When
        wishRepository.simulateChange()

        // Then
        XCTAssertEqual(router.wishesChangedToken, before)
    }

    // MARK: TC-5 (수동 TC 의 상태 이전 부분)

    func test_GH99_TC5_좁은창으로바뀌면_보던위시가_탭에쌓인상세로이어진다() {
        // Given
        sut.send(.tapSidebar(.wantToGo))
        router.push(.wishDetail(id: "w3", isFinished: false))

        // When
        router.setRegularLayout(false)

        // Then
        XCTAssertEqual(router.selectedTab, .wish)
        XCTAssertEqual(router.homeCategory, .wantToGo)
        XCTAssertEqual(router.wishPath, [.wishDetail(id: "w3", isFinished: false)])
        XCTAssertNil(router.padSelection)
    }

    func test_GH99_TC5_넓어지면_탭에쌓인상세가_상세열로옮겨간다() {
        // Given
        router.setRegularLayout(false)
        router.selectedTab = .finished
        router.finishedPath = [.wishDetail(id: "w4", isFinished: true)]

        // When
        router.setRegularLayout(true)

        // Then
        XCTAssertEqual(router.padSection, .finished)
        XCTAssertEqual(router.padSelection, PadWishSelection(id: "w4", isFinished: true))
        XCTAssertTrue(router.finishedPath.isEmpty)
    }

    // MARK: TC-13

    func test_GH99_TC13_위젯링크로_진행중위시를열면_그카테고리와상세열이열린다() {
        // Given
        wishRepository.fetchWishResult = [Wish(id: "w1", category: .wantToGet, title: "카메라", isSuccess: false)]
        sut.send(.tapSidebar(.settings))

        // When
        let handled = router.open(url: url(.wish(id: "w1", source: .checkWidget)))

        // Then
        XCTAssertEqual(handled, .wish(id: "w1", source: .checkWidget))
        XCTAssertEqual(router.padSection, .category(.wantToGet))
        XCTAssertEqual(router.homeCategory, .wantToGet)
        XCTAssertEqual(router.padSelection, PadWishSelection(id: "w1", isFinished: false))
        XCTAssertTrue(router.wishPath.isEmpty)
    }

    func test_GH99_TC13_위젯링크로_완료위시를열면_이룬싶과상세열이열린다() {
        // Given
        wishRepository.fetchWishResult = [Wish(id: "w2", title: "캠핑", isSuccess: true)]

        // When
        router.open(url: url(.wish(id: "w2", source: .checkWidget)))

        // Then
        XCTAssertEqual(router.padSection, .finished)
        XCTAssertEqual(router.padSelection, PadWishSelection(id: "w2", isFinished: true))
    }

    // MARK: TC-15

    func test_GH99_TC15_사이드바항목을누르면_sidebar_item클릭로그가_type과함께1건전송된다() {
        // When
        sut.send(.tapSidebar(.badges))
        sut.send(.tapSidebar(.wantToGo))

        // Then
        let events = clickEvents(objectId: .sidebarItem)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.screen, .home)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, "badge")
        XCTAssertEqual(events.last?.extraParameters?[.type] as? String, "category")
        XCTAssertEqual(events.last?.extraParameters?[.category] as? String, Category.wantToGo.rawValue)
        XCTAssertEqual(router.padSection, .category(.wantToGo))
    }

    // MARK: TC-16

    func test_GH99_TC16_가로로처음보이면_pad_layout노출로그가_three_column으로1건전송된다() {
        // When
        sut.send(.onAppear(isLandscape: true))
        sut.send(.onAppear(isLandscape: false))

        // Then
        let events = impressionEvents(objectId: .padLayout)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .home)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, "three_column")
    }

    func test_GH99_TC16_세로로처음보이면_two_column으로보낸다() {
        // When
        sut.send(.onAppear(isLandscape: false))

        // Then
        XCTAssertEqual(impressionEvents(objectId: .padLayout).first?.extraParameters?[.type] as? String, "two_column")
    }
}
