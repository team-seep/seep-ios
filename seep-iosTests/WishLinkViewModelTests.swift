import XCTest
import Combine

@testable import seep_ios_dev

/// 갖고 싶어요 상품 링크 칸·미리보기 카드 (GH-29).
final class WishLinkViewModelTests: XCTestCase {
    private var mockProvider: MockLinkMetadataProvider!
    private var mockCache: MockLinkPreviewCache!
    private var mockLogManager: MockLogManager!
    private var cancellables = Set<AnyCancellable>()

    private let link = "https://store.example.com/p/1"
    private lazy var preview = LinkPreview(link: link, title: "무선 노이즈캔슬링 헤드폰", imageData: Data([0x1]))

    override func setUp() {
        super.setUp()
        mockProvider = MockLinkMetadataProvider()
        mockCache = MockLinkPreviewCache()
        mockLogManager = MockLogManager()
    }

    override func tearDown() {
        mockProvider = nil
        mockCache = nil
        mockLogManager = nil
        cancellables = []
        super.tearDown()
    }

    private func makeViewModel(
        mode: WishLinkViewModel.Mode,
        category: seep_ios_dev.Category = .wantToGet,
        wishId: String? = nil,
        link: String = ""
    ) -> WishLinkViewModel {
        return WishLinkViewModel(
            config: .init(mode: mode, category: category, wishId: wishId, link: link),
            dependency: .init(
                linkMetadataProvider: mockProvider,
                linkPreviewCache: mockCache,
                logManager: mockLogManager,
                debounceInterval: nil
            )
        )
    }

    private func events(objectId: LogObjectId) -> [any LogEventType] {
        return mockLogManager.sentEvents.filter { ($0.extraParameters?[.objectId] as? LogObjectId) == objectId }
    }

    // MARK: GH-29 TC1

    func test_GH29_TC1_갖고싶어요작성화면이면_링크칸이보이고_하고싶어요로바꾸면_사라진다() {
        // Given
        let viewModel = makeViewModel(mode: .write)
        XCTAssertTrue(viewModel.output.isVisible.value)

        // When
        viewModel.input.changeCategory.send(.wantToDo)

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
    }

    func test_GH29_TC1_하고싶어요작성화면이면_링크칸이없고_갖고싶어요로바꾸면_보인다() {
        // Given
        let viewModel = makeViewModel(mode: .write, category: .wantToDo)
        XCTAssertFalse(viewModel.output.isVisible.value)

        // When
        viewModel.input.changeCategory.send(.wantToGet)

        // Then
        XCTAssertTrue(viewModel.output.isVisible.value)
    }

    // MARK: GH-29 TC3

    func test_GH29_TC3_링크형식이아닌글을입력하면_형식안내가뜨고_invalid가Reactor로넘어간다() {
        // Given
        let viewModel = makeViewModel(mode: .write)

        // When
        viewModel.input.inputText.send("헤드폰 매장 어딘가")

        // Then
        XCTAssertEqual(viewModel.output.errorMessage.value, Strings.Write.Link.errorInvalid)
        XCTAssertEqual(viewModel.output.linkInput.value, .invalid)
        XCTAssertEqual(viewModel.output.preview.value, .hidden)
        XCTAssertTrue(mockProvider.fetchedLinks.isEmpty)
    }

    func test_GH29_TC3_형식오류뒤에올바른링크로고치면_안내가사라진다() {
        // Given
        let viewModel = makeViewModel(mode: .write)
        viewModel.input.inputText.send("store.example.com")

        // When
        viewModel.input.inputText.send(link)

        // Then
        XCTAssertNil(viewModel.output.errorMessage.value)
        XCTAssertEqual(viewModel.output.linkInput.value, .valid(link))
    }

    func test_GH29_TC3_http와https외의주소나_2000자를넘는링크는_invalid다() {
        // Given
        let longLink = "https://store.example.com/" + String(repeating: "a", count: WishLinkInput.maxLength)

        // When
        let inputs = [
            WishLinkInput(text: "ftp://store.example.com/p/1"),
            WishLinkInput(text: "javascript:alert(1)"),
            WishLinkInput(text: "https://"),
            WishLinkInput(text: longLink)
        ]

        // Then
        XCTAssertEqual(inputs, [.invalid, .invalid, .invalid, .invalid])
        XCTAssertEqual(WishLinkInput(text: "   "), .empty)
    }

    // MARK: GH-29 TC4

    func test_GH29_TC4_앞뒤공백이있는링크를입력하면_공백을지운값이넘어간다() {
        // Given
        let viewModel = makeViewModel(mode: .write)

        // When
        viewModel.input.inputText.send("  \(link)\n")

        // Then
        XCTAssertEqual(viewModel.output.linkInput.value, .valid(link))
        XCTAssertEqual(mockProvider.fetchedLinks, [link])
    }

    // MARK: GH-29 TC5

    func test_GH29_TC5_제공자가제목이미지를돌려주면_불러오는중다음에_제목과도메인카드가뜬다() {
        // Given
        mockProvider.isDeferred = true
        let viewModel = makeViewModel(mode: .write)
        var states: [WishLinkPreviewState] = []
        viewModel.output.preview
            .sink { states.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.inputText.send(link)
        mockProvider.complete(at: 0, with: preview)

        // Then
        XCTAssertEqual(states, [.hidden, .loading(domain: "store.example.com"), .loaded(preview)])
        XCTAssertEqual(preview.domain, "store.example.com")
    }

    func test_GH29_TC5_응답이오기전에링크가바뀌면_이전응답은버린다() {
        // Given
        mockProvider.isDeferred = true
        let viewModel = makeViewModel(mode: .write)
        let newLink = "https://www.shop.example.com/p/2"
        viewModel.input.inputText.send(link)
        viewModel.input.inputText.send(newLink)

        // When
        mockProvider.complete(at: 0, with: preview)

        // Then
        XCTAssertEqual(viewModel.output.preview.value, .loading(domain: "shop.example.com"))
    }

    // MARK: GH-29 TC6

    func test_GH29_TC6_제공자가실패하면_도메인만있는카드가뜨고_링크는그대로넘어간다() {
        // Given
        mockProvider.fetchPreviewResult = nil
        let viewModel = makeViewModel(mode: .write)

        // When
        viewModel.input.inputText.send(link)

        // Then
        XCTAssertEqual(viewModel.output.preview.value, .failed(domain: "store.example.com"))
        XCTAssertEqual(viewModel.output.linkInput.value, .valid(link))
        XCTAssertNil(viewModel.output.errorMessage.value)
    }

    // MARK: GH-29 TC8

    func test_GH29_TC8_상세에서링크카드를탭하면_Safari열기route와_wish_link클릭로그가1건전송된다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)
        var routes: [WishLinkViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        viewModel.input.viewDidLoad.send(())

        // When
        viewModel.input.didTapCard.send(())

        // Then
        XCTAssertEqual(routes.count, 1)
        if case .openSafari(let url) = routes.first {
            XCTAssertEqual(url.absoluteString, link)
        } else {
            XCTFail("openSafari route 가 아니다")
        }
        let clickEvents = events(objectId: .wishLink)
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.name, .click)
        XCTAssertEqual(clickEvents.first?.screen, .wishDetail)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .card)
    }

    func test_GH29_TC8_링크가없는위시상세면_링크섹션이없다() {
        // Given
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: "")

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertFalse(viewModel.output.isVisible.value)
        XCTAssertTrue(mockProvider.fetchedLinks.isEmpty)
    }

    // MARK: GH-29 TC10

    func test_GH29_TC10_캐시된메타데이터가있으면_제공자를부르지않고_카드를바로보여준다() {
        // Given
        mockCache.previews["wish-1"] = preview
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertTrue(mockProvider.fetchedLinks.isEmpty)
        XCTAssertEqual(viewModel.output.preview.value, .loaded(preview))
        XCTAssertTrue(viewModel.output.isVisible.value)
    }

    func test_GH29_TC10_캐시가없으면_상세에서불러온메타데이터를위시id로캐시한다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertEqual(mockProvider.fetchedLinks, [link])
        XCTAssertEqual(mockCache.savedWishIds, ["wish-1"])
        XCTAssertEqual(mockCache.previews["wish-1"], preview)
    }

    func test_GH29_TC10_실패한미리보기는_캐시하지않는다() {
        // Given
        mockProvider.fetchPreviewResult = nil
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertEqual(viewModel.output.preview.value, .failed(domain: "store.example.com"))
        XCTAssertTrue(mockCache.savedWishIds.isEmpty)
    }

    // MARK: GH-29 TC11

    func test_GH29_TC11_작성중미리보기카드가처음뜨면_impression로그가1건만전송된다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .write)

        // When
        viewModel.input.inputText.send(link)
        viewModel.input.inputText.send("")
        viewModel.input.inputText.send("https://store.example.com/p/2")

        // Then
        let impressions = events(objectId: .wishLinkPreview)
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.name, .impression)
        XCTAssertEqual(impressions.first?.screen, .write)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .card)
    }

    func test_GH29_TC11_수정화면에서실패카드가뜨면_wish_edit화면으로impression이전송된다() {
        // Given
        mockProvider.fetchPreviewResult = nil
        let viewModel = makeViewModel(mode: .edit, wishId: "wish-1", link: link)

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        let impressions = events(objectId: .wishLinkPreview)
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .wishEdit)
    }

    func test_GH29_TC11_상세에서카드가떠도_impression은보내지않는다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertTrue(events(objectId: .wishLinkPreview).isEmpty)
    }

    // MARK: GH-29 TC12

    func test_GH29_TC12_붙여넣기를누르면_칸에링크가들어가고_paste_wish_link클릭로그가1건전송된다() {
        // Given
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .write)
        var texts: [String] = []
        viewModel.output.text
            .sink { texts.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.paste.send(" \(link) ")

        // Then
        XCTAssertEqual(texts, [link])
        XCTAssertEqual(viewModel.output.linkInput.value, .valid(link))
        let clickEvents = events(objectId: .pasteWishLink)
        XCTAssertEqual(clickEvents.count, 1)
        XCTAssertEqual(clickEvents.first?.name, .click)
        XCTAssertEqual(clickEvents.first?.screen, .write)
        XCTAssertEqual(clickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    // MARK: GH-29 TC13

    func test_GH29_TC13_수정에서링크를바꿔돌아오면_예전캐시를지우고_새링크로다시불러온다() {
        // Given
        mockCache.previews["wish-1"] = preview
        mockProvider.fetchPreviewResult = LinkPreview(link: "https://shop.example.com/p/2", title: "새 상품", imageData: nil)
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)
        viewModel.input.viewDidLoad.send(())

        // When
        viewModel.input.reloadWish.send(Wish(
            id: "wish-1",
            category: .wantToGet,
            title: "헤드폰",
            link: "https://shop.example.com/p/2"
        ))

        // Then
        XCTAssertEqual(mockCache.removedWishIds.first, "wish-1")
        XCTAssertEqual(mockProvider.fetchedLinks, ["https://shop.example.com/p/2"])
        XCTAssertEqual(mockCache.previews["wish-1"]?.link, "https://shop.example.com/p/2")
    }

    func test_GH29_TC13_캐시의링크가위시링크와다르면_캐시를지우고다시불러온다() {
        // Given
        mockCache.previews["wish-1"] = LinkPreview(link: "https://old.example.com", title: "예전", imageData: nil)
        mockProvider.fetchPreviewResult = preview
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertEqual(mockCache.removedWishIds, ["wish-1"])
        XCTAssertEqual(mockProvider.fetchedLinks, [link])
        XCTAssertEqual(viewModel.output.preview.value, .loaded(preview))
    }

    func test_GH29_TC13_수정에서링크를지워돌아오면_캐시를지우고_링크섹션을숨긴다() {
        // Given
        mockCache.previews["wish-1"] = preview
        let viewModel = makeViewModel(mode: .detail, wishId: "wish-1", link: link)
        viewModel.input.viewDidLoad.send(())

        // When
        viewModel.input.reloadWish.send(Wish(id: "wish-1", category: .wantToGet, title: "헤드폰", link: ""))

        // Then
        XCTAssertEqual(mockCache.removedWishIds, ["wish-1"])
        XCTAssertFalse(viewModel.output.isVisible.value)
        XCTAssertEqual(viewModel.output.preview.value, .hidden)
    }
}
