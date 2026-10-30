import XCTest

@testable import seep_ios

private final class StubDeepLinkStore: ReservedDeepLinkStoring {
    var reservedDeepLink = ""
}

/// 탭 바·적기 시트 (GH-64 R-1 ~ R-11)
final class MainTabFeatureTests: ViewModelTestCase {
    private var router: AppRouter!
    private var sut: MainTabViewModel!

    override func setUp() {
        super.setUp()
        router = AppRouter(dependency: .init(wishRepository: MockWishRepository(), deepLinkStore: StubDeepLinkStore()))
        sut = MainTabViewModel(dependency: .init(router: router, logManager: logManager))
    }

    override func tearDown() {
        sut = nil
        router = nil
        super.tearDown()
    }

    // MARK: GH-64 TC2

    func test_GH64_TC2_적기탭을누르면_탭은그대로이고_시트가뜨며_클릭로그1건() {
        // Given
        router.homeCategory = .wantToDo

        // When
        sut.send(.tapTab(.write))

        // Then
        XCTAssertEqual(router.selectedTab, .wish)
        XCTAssertTrue(sut.state.isWriteSheetPresented)
        XCTAssertEqual(sut.highlightedCategory, .wantToDo)
        let clicks = clickEvents(objectId: .tabWrite)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .home)
        XCTAssertEqual(clicks.first?.extraParameters?[.objectType] as? LogObjectType, .tab)
    }

    func test_GH64_TC2_탭클릭로그는_지금탭의화면이름으로보낸다() {
        // Given
        sut.send(.tapTab(.settings))

        // When
        sut.send(.tapTab(.finished))

        // Then
        XCTAssertEqual(router.selectedTab, .finished)
        XCTAssertEqual(clickEvents(objectId: .tabSettings).first?.screen, .home)
        XCTAssertEqual(clickEvents(objectId: .tabFinished).first?.screen, .settings)
    }

    // MARK: GH-64 TC3

    func test_GH64_TC3_시트에서카테고리를고르면_시트가닫히고_작성화면이그카테고리로열리며_로그1건() {
        // Given
        sut.send(.tapTab(.write))

        // When
        sut.send(.selectWriteCategory(.wantToGet))

        // Then
        XCTAssertFalse(sut.state.isWriteSheetPresented)
        XCTAssertEqual(router.writeCategory, .wantToGet)
        let clicks = clickEvents(objectId: .writeCategory)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .writeCategorySheet)
        XCTAssertEqual(clicks.first?.extraParameters?[.category] as? String, Category.wantToGet.rawValue)
    }

    // MARK: GH-64 TC4

    func test_GH64_TC4_시트를내리면_아무화면도열리지않는다() {
        // Given
        sut.send(.tapTab(.write))

        // When
        sut.send(.dismissWriteSheet)

        // Then
        XCTAssertFalse(sut.state.isWriteSheetPresented)
        XCTAssertNil(router.writeCategory)
    }

    // MARK: GH-64 TC23

    func test_GH64_TC23_지금탭을다시누르면_쌓인화면이있으면루트로_없으면맨위로() {
        // Given
        router.wishPath = [.search(finishedOnly: false)]

        // When
        sut.send(.tapTab(.wish))

        // Then
        XCTAssertTrue(router.wishPath.isEmpty)
        XCTAssertNil(router.scrollToTopToken[.wish])

        // When
        sut.send(.tapTab(.wish))

        // Then
        XCTAssertEqual(router.scrollToTopToken[.wish], 1)
    }

    // MARK: GH-64 TC6

    func test_GH64_TC6_이룬싶탭을열면_빨간점이사라진다() {
        // Given
        router.showsFinishedDot = true

        // When
        sut.send(.tapTab(.finished))

        // Then
        XCTAssertFalse(router.showsFinishedDot)
    }

    // MARK: GH-64 TC43 (GH-49 R-12)

    func test_GH64_TC43_단축어작성링크는_시트가떠있으면_모두닫은뒤_작성화면을띄운다() {
        // Given
        router.mainDidAppear()
        router.modalDidAppear()

        // When
        let handled = router.openFromIntent(.add(.wantToGo, source: .shortcut))

        // Then
        XCTAssertEqual(handled, .add(.wantToGo, source: .shortcut))
        XCTAssertEqual(router.dismissAllModalsToken, 1)
        XCTAssertNil(router.writeCategory)

        // When — 시트가 닫히면
        router.modalDidDisappear()

        // Then
        XCTAssertEqual(router.writeCategory, .wantToGo)
    }
}
