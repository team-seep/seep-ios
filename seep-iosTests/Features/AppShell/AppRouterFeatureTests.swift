import XCTest

@testable import seep_ios

private final class StubDeepLinkStore: ReservedDeepLinkStoring {
    var reservedDeepLink = ""
}

/// 탭·딥링크 이동 (GH-64 A-4, R-30)
final class AppRouterFeatureTests: ViewModelTestCase {
    private var wishRepository: MockWishRepository!
    private var deepLinkStore: StubDeepLinkStore!
    private var sut: AppRouter!

    override func setUp() {
        super.setUp()
        wishRepository = MockWishRepository()
        deepLinkStore = StubDeepLinkStore()
        sut = AppRouter(dependency: .init(wishRepository: wishRepository, deepLinkStore: deepLinkStore))
        sut.mainDidAppear()
    }

    override func tearDown() {
        sut = nil
        deepLinkStore = nil
        wishRepository = nil
        super.tearDown()
    }

    private func url(_ deepLink: WidgetDeepLink) -> URL {
        deepLink.url ?? URL(fileURLWithPath: "/")
    }

    // MARK: GH-64 TC41

    func test_GH64_TC41_진행중위시_상세링크면_싶탭에_상세를쌓는다() {
        // Given
        wishRepository.fetchWishResult = [Wish(id: "w1", title: "서핑 배우기", isSuccess: false)]
        sut.selectedTab = .settings

        // When
        let handled = sut.open(url: url(.wish(id: "w1", source: .lockscreenDday)))

        // Then
        XCTAssertEqual(handled, .wish(id: "w1", source: .lockscreenDday))
        XCTAssertEqual(sut.selectedTab, .wish)
        XCTAssertEqual(sut.wishPath, [.wishDetail(id: "w1", isFinished: false)])
        XCTAssertEqual(deepLinkStore.reservedDeepLink, "")
    }

    func test_GH64_TC41_지워진위시면_이동하지않는다() {
        // Given
        wishRepository.fetchWishResult = []

        // When
        let handled = sut.open(url: url(.wish(id: "gone", source: .checkWidget)))

        // Then
        XCTAssertNil(handled)
        XCTAssertTrue(sut.wishPath.isEmpty)
    }

    // MARK: GH-64 TC42

    func test_GH64_TC42_완료위시_상세링크면_이룬싶탭에서_연다() {
        // Given
        wishRepository.fetchWishResult = [Wish(id: "w2", title: "캠핑", isSuccess: true)]

        // When
        sut.open(url: url(.wish(id: "w2", source: .checkWidget)))

        // Then
        XCTAssertEqual(sut.selectedTab, .finished)
        XCTAssertEqual(sut.finishedPath, [.wishDetail(id: "w2", isFinished: true)])
        XCTAssertTrue(sut.wishPath.isEmpty)
    }

    // MARK: GH-64 TC43

    func test_GH64_TC43_작성링크면_작성화면을_그카테고리로연다() {
        // Given / When
        let handled = sut.open(url: url(.add(.wantToGet, source: .control)))

        // Then
        XCTAssertEqual(handled, .add(.wantToGet, source: .control))
        XCTAssertEqual(sut.writeCategory, .wantToGet)
    }

    func test_GH64_TC43_작성화면이떠있을때_작성링크면_카테고리만바꾼다() {
        // Given
        sut.writeCategory = .wantToDo

        // When
        sut.open(url: url(.add(.wantToGo, source: .shortcut)))

        // Then
        XCTAssertEqual(sut.writeCategory, .wantToGo)
    }

    func test_GH64_TC43_메인이뜨기전링크는_맡아두었다가_메인이뜰때한번처리한다() {
        // Given
        let coldRouter = AppRouter(dependency: .init(wishRepository: wishRepository, deepLinkStore: deepLinkStore))

        // When
        let beforeMain = coldRouter.open(url: url(.add(.wantToDo, source: .control)))

        // Then
        XCTAssertNil(beforeMain)
        XCTAssertNil(coldRouter.writeCategory)
        XCTAssertFalse(deepLinkStore.reservedDeepLink.isEmpty)

        // When
        let afterMain = coldRouter.mainDidAppear()

        // Then
        XCTAssertEqual(afterMain, .add(.wantToDo, source: .control))
        XCTAssertEqual(coldRouter.writeCategory, .wantToDo)
        XCTAssertEqual(deepLinkStore.reservedDeepLink, "")
    }

    // MARK: GH-64 TC44

    func test_GH64_TC44_다른탭에_push가있으면_링크를버리고지운다() {
        // Given
        wishRepository.fetchWishResult = [Wish(id: "w1", isSuccess: false)]
        sut.finishedPath = [.wishDetail(id: "other", isFinished: true)]

        // When
        let handled = sut.open(url: url(.wish(id: "w1", source: .lockscreenDday)))

        // Then
        XCTAssertNil(handled)
        XCTAssertTrue(sut.wishPath.isEmpty)
        XCTAssertEqual(deepLinkStore.reservedDeepLink, "")
    }

    func test_GH64_TC44_시트가떠있으면_작성링크도버린다() {
        // Given
        sut.modalDidAppear()

        // When
        let handled = sut.open(url: url(.add(.wantToDo, source: .control)))

        // Then
        XCTAssertNil(handled)
        XCTAssertNil(sut.writeCategory)

        // When — 시트가 닫히면 다시 받는다
        sut.modalDidDisappear()
        let handledAfter = sut.open(url: url(.add(.wantToDo, source: .control)))

        // Then
        XCTAssertEqual(handledAfter, .add(.wantToDo, source: .control))
    }
}
