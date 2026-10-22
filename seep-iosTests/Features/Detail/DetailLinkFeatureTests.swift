import XCTest

@testable import seep_ios_dev

/// 상세 "링크" 섹션 (GH-29 R-4·R-5, GH-59 R-6).
/// 작성·수정의 링크 칸은 `WishLinkViewModelTests`(작성 폼) 쪽에 남는다
final class DetailLinkFeatureTests: ViewModelTestCase {
    private var mockProvider: MockLinkMetadataProvider!
    private var mockCache: MockLinkPreviewCache!

    private let link = "https://store.example.com/p/1"
    private lazy var preview = LinkPreview(link: link, title: "무선 노이즈캔슬링 헤드폰", imageData: Data([0x1]))

    override func setUp() {
        super.setUp()
        mockProvider = MockLinkMetadataProvider()
        mockCache = MockLinkPreviewCache()
    }

    override func tearDown() {
        mockProvider = nil
        mockCache = nil
        super.tearDown()
    }

    private func makeViewModel(category: seep_ios_dev.Category = .wantToGet, link: String) -> DetailLinkViewModel {
        DetailLinkViewModel(
            config: .init(wish: Wish(id: "wish-1", category: category, title: "헤드폰", link: link)),
            dependency: .init(linkMetadataProvider: mockProvider, linkPreviewCache: mockCache, logManager: logManager)
        )
    }

    private func events(objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter { ($0.extraParameters?[.objectId] as? LogObjectId) == objectId }
    }

    // MARK: GH-29 TC8 · TC10 · TC11 · TC13

    func test_GH29_TC8_상세에서링크카드를탭하면_링크열기route와_wish_link클릭로그가1건전송된다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(link: link)
        viewModel.send(.load)

        // When
        viewModel.send(.tapCard)

        // Then
        XCTAssertEqual(viewModel.route, .openURL(URL(string: link)!))
        let clickEvents = events(objectId: .wishLink)
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.name, .click)
        XCTAssertEqual(clickEvents.first?.screen, .wishDetail)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .card)
    }

    func test_GH29_TC8_링크가없는위시상세면_링크섹션이없다() {
        // Given
        let viewModel = makeViewModel(link: "")

        // When
        viewModel.send(.load)

        // Then
        XCTAssertFalse(viewModel.state.isVisible)
        XCTAssertTrue(mockProvider.fetchedLinks.isEmpty)
    }

    func test_GH29_TC10_캐시된메타데이터가있으면_제공자를부르지않고_카드를바로보여준다() {
        // Given
        mockCache.previews["wish-1"] = preview
        let viewModel = makeViewModel(link: link)

        // When
        viewModel.send(.load)

        // Then
        XCTAssertTrue(mockProvider.fetchedLinks.isEmpty)
        XCTAssertEqual(viewModel.state.preview, .loaded(preview))
        XCTAssertTrue(viewModel.state.isVisible)
    }

    func test_GH29_TC10_캐시가없으면_상세에서불러온메타데이터를위시id로캐시한다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(link: link)

        // When
        viewModel.send(.load)

        // Then
        XCTAssertEqual(mockProvider.fetchedLinks, [link])
        XCTAssertEqual(mockCache.savedWishIds, ["wish-1"])
        XCTAssertEqual(mockCache.previews["wish-1"], preview)
    }

    func test_GH29_TC10_실패한미리보기는_캐시하지않는다() {
        // Given
        mockProvider.fetchPreviewResult = nil
        let viewModel = makeViewModel(link: link)

        // When
        viewModel.send(.load)

        // Then
        XCTAssertEqual(viewModel.state.preview, .failed(domain: "store.example.com"))
        XCTAssertTrue(mockCache.savedWishIds.isEmpty)
    }

    func test_GH29_TC11_상세에서카드가떠도_impression은보내지않는다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(link: link)

        // When
        viewModel.send(.load)

        // Then
        XCTAssertTrue(events(objectId: .wishLinkPreview).isEmpty)
    }

    func test_GH29_TC13_수정에서링크를바꿔돌아오면_예전캐시를지우고_새링크로다시불러온다() {
        // Given
        mockCache.previews["wish-1"] = preview
        mockProvider.fetchPreviewResult = LinkPreview(link: "https://shop.example.com/p/2", title: "새 상품", imageData: nil)
        let viewModel = makeViewModel(link: link)
        viewModel.send(.load)

        // When
        viewModel.send(.reload(Wish(
            id: "wish-1",
            category: .wantToGet,
            title: "헤드폰",
            link: "https://shop.example.com/p/2"
        )))

        // Then
        XCTAssertEqual(mockCache.removedWishIds.first, "wish-1")
        XCTAssertEqual(mockProvider.fetchedLinks, ["https://shop.example.com/p/2"])
        XCTAssertEqual(mockCache.previews["wish-1"]?.link, "https://shop.example.com/p/2")
    }

    func test_GH29_TC13_캐시의링크가위시링크와다르면_캐시를지우고다시불러온다() {
        // Given
        mockCache.previews["wish-1"] = LinkPreview(link: "https://old.example.com", title: "예전", imageData: nil)
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(link: link)

        // When
        viewModel.send(.load)

        // Then
        XCTAssertEqual(mockCache.removedWishIds, ["wish-1"])
        XCTAssertEqual(mockProvider.fetchedLinks, [link])
        XCTAssertEqual(viewModel.state.preview, .loaded(preview))
    }

    func test_GH29_TC13_수정에서링크를지워돌아오면_캐시를지우고_링크섹션을숨긴다() {
        // Given
        mockCache.previews["wish-1"] = preview
        let viewModel = makeViewModel(link: link)
        viewModel.send(.load)

        // When
        viewModel.send(.reload(Wish(id: "wish-1", category: .wantToGet, title: "헤드폰", link: "")))

        // Then
        XCTAssertEqual(mockCache.removedWishIds, ["wish-1"])
        XCTAssertFalse(viewModel.state.isVisible)
        XCTAssertEqual(viewModel.state.preview, .hidden)
    }

    // MARK: 회귀

    func test_회귀_갖고싶어요가아니면_링크가있어도_링크섹션이없다() {
        // Given / When
        let viewModel = makeViewModel(category: .wantToDo, link: link)

        // Then
        XCTAssertFalse(viewModel.state.isVisible)
    }
}
