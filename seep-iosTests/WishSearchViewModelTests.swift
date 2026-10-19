import XCTest
import Combine

@testable import seep_ios_dev

/// 위시 검색 화면 (GH-32).
final class WishSearchViewModelTests: XCTestCase {
    private var mockRepository: MockWishRepository!
    private var mockLogManager: MockLogManager!
    private var cancellables: Set<AnyCancellable>!

    private let now = Date()

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockLogManager = MockLogManager()
        cancellables = []
    }

    override func tearDown() {
        mockRepository = nil
        mockLogManager = nil
        cancellables = nil
        super.tearDown()
    }

    private func makeViewModel() -> WishSearchViewModel {
        return WishSearchViewModel(dependency: .init(
            wishRepository: mockRepository,
            wishService: MockWishService(),
            logManager: mockLogManager
        ))
    }

    private func days(_ value: Int) -> Date {
        return now.addingTimeInterval(TimeInterval(value * 24 * 60 * 60))
    }

    private func objectIds(of events: [any LogEventType]) -> [String] {
        return events.compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
    }

    // MARK: GH-32 TC1

    func test_GH32_TC1_검색하면_카테고리섹션순으로묶이고_결과없는섹션은숨긴다() {
        // Given
        mockRepository.searchWishesResult = [
            Wish(id: "go", category: .wantToGo, title: "제주 귤밭 카페"),
            Wish(id: "do", category: .wantToDo, title: "제주도 한 달 살기")
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send("제주")

        // Then
        let sections = viewModel.output.sections.value
        XCTAssertEqual(sections.map(\.category), [.wantToDo, .wantToGo])
        XCTAssertEqual(sections.map { $0.items.map(\.wish.id) }, [["do"], ["go"]])
        XCTAssertEqual(viewModel.output.resultCount.value, 2)
        XCTAssertNil(viewModel.output.emptyKeyword.value)
        XCTAssertEqual(mockRepository.searchWishesCalls, ["제주"])
    }

    func test_GH32_TC1_제목에서찾은결과는_일치범위를강조한다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", category: .wantToDo, title: "한 달 제주 살기")]
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send("제주")

        // Then
        let item = viewModel.output.sections.value.first?.items.first
        XCTAssertEqual(item?.titleHighlightRange, NSRange(location: 4, length: 2))
        XCTAssertNil(item?.memoSnippet)
    }

    // MARK: GH-32 TC3

    func test_GH32_TC3_메모에서만찾은결과는_메모한줄을가진다() {
        // Given
        mockRepository.searchWishesResult = [
            Wish(id: "get", category: .wantToGet, title: "필름 카메라", memo: "제주 가기 전에 사서 연습하기")
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send("제주")

        // Then
        let item = viewModel.output.sections.value.first?.items.first
        XCTAssertNil(item?.titleHighlightRange)
        XCTAssertEqual(item?.memoSnippet?.text, "제주 가기 전에 사서 연습하기")
    }

    // MARK: GH-32 TC4

    func test_GH32_TC4_대소문자와앞뒤공백이달라도_다듬은검색어로찾는다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", title: "Nike 운동화")]
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send("  nike ")

        // Then
        XCTAssertEqual(mockRepository.searchWishesCalls, ["nike"])
        XCTAssertEqual(viewModel.output.sections.value.first?.items.first?.titleHighlightRange, NSRange(location: 0, length: 4))
    }

    // MARK: GH-32 TC5

    func test_GH32_TC5_공백만입력하면_조회하지않고_결과와안내가모두비어있다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", title: "제주")]
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send("   ")

        // Then
        XCTAssertTrue(mockRepository.searchWishesCalls.isEmpty)
        XCTAssertTrue(viewModel.output.sections.value.isEmpty)
        XCTAssertNil(viewModel.output.resultCount.value)
        XCTAssertNil(viewModel.output.emptyKeyword.value)
        XCTAssertTrue(mockLogManager.sentEvents.isEmpty)
    }

    func test_GH32_TC5_검색어를지우면_이전결과가사라진다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", title: "제주")]
        let viewModel = makeViewModel()
        viewModel.input.inputKeyword.send("제주")

        // When
        viewModel.input.inputKeyword.send("")

        // Then
        XCTAssertTrue(viewModel.output.sections.value.isEmpty)
        XCTAssertNil(viewModel.output.resultCount.value)
    }

    // MARK: GH-32 TC6

    func test_GH32_TC6_일치하는위시가없으면_결과없음안내에검색어를넘긴다() {
        // Given
        mockRepository.searchWishesResult = []
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send(" 스카이다이빙 ")

        // Then
        XCTAssertEqual(viewModel.output.emptyKeyword.value, "스카이다이빙")
        XCTAssertNil(viewModel.output.resultCount.value)
        XCTAssertTrue(viewModel.output.sections.value.isEmpty)
    }

    // MARK: GH-32 TC7

    func test_GH32_TC7_같은카테고리안에서_미완료가위이고_미완료끼리는마감순이다() {
        // Given
        mockRepository.searchWishesResult = [
            Wish(id: "finished", category: .wantToDo, title: "제주 1", endDate: days(1), isSuccess: true),
            Wish(id: "noDeadline", category: .wantToDo, title: "제주 2"),
            Wish(id: "far", category: .wantToDo, title: "제주 3", endDate: days(20)),
            Wish(id: "near", category: .wantToDo, title: "제주 4", endDate: days(2))
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send("제주")

        // Then
        XCTAssertEqual(
            viewModel.output.sections.value.first?.items.map(\.wish.id),
            ["near", "far", "noDeadline", "finished"]
        )
    }

    // MARK: GH-32 TC8

    func test_GH32_TC8_결과를탭하면_해당위시상세로이동한다() {
        // Given
        let finished = Wish(id: "finished", category: .wantToGet, title: "제주 감귤", isSuccess: true)
        mockRepository.searchWishesResult = [Wish(id: "do", category: .wantToDo, title: "제주도"), finished]
        let viewModel = makeViewModel()
        viewModel.input.inputKeyword.send("제주")
        var pushedWish: Wish?
        viewModel.output.route
            .sink { route in
                if case .pushWishDetail(let reactor) = route {
                    pushedWish = reactor.initialState.wish
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapResult.send(IndexPath(item: 0, section: 1))

        // Then
        XCTAssertEqual(pushedWish?.id, "finished")
        XCTAssertEqual(pushedWish?.isSuccess, true)
    }

    // MARK: GH-32 TC9

    func test_GH32_TC9_상세에서위시를삭제하면_같은검색어로다시찾아_지운위시가빠진다() {
        // Given
        let target = Wish(id: "target", category: .wantToDo, title: "제주도")
        let other = Wish(id: "other", category: .wantToDo, title: "제주 맛집")
        mockRepository.searchWishesResult = [target, other]
        let viewModel = makeViewModel()
        viewModel.input.inputKeyword.send("제주")
        var reactor: WishDetailReactor?
        var didChangeCount = 0
        viewModel.output.route
            .sink { route in
                if case .pushWishDetail(let pushed) = route { reactor = pushed }
            }
            .store(in: &cancellables)
        viewModel.output.didChangeWishes
            .sink { didChangeCount += 1 }
            .store(in: &cancellables)
        viewModel.input.didTapResult.send(IndexPath(item: 0, section: 0))

        // When
        mockRepository.searchWishesResult = [other]
        reactor?.deleteWishPublisher.send(target)

        // Then
        XCTAssertEqual(mockRepository.searchWishesCalls, ["제주", "제주"])
        XCTAssertEqual(viewModel.output.sections.value.first?.items.map(\.wish.id), ["other"])
        XCTAssertEqual(didChangeCount, 1)
    }

    // MARK: GH-32 TC12

    func test_GH32_TC12_결과셀을탭하면_search_result클릭로그가결과수와카테고리를담아1건전송된다() {
        // Given
        mockRepository.searchWishesResult = [
            Wish(id: "do", category: .wantToDo, title: "제주도"),
            Wish(id: "go", category: .wantToGo, title: "제주 카페")
        ]
        let viewModel = makeViewModel()
        viewModel.input.inputKeyword.send("제주")

        // When
        viewModel.input.didTapResult.send(IndexPath(item: 0, section: 1))

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        let parameters = mockLogManager.sentEvents.first?.parameters
        XCTAssertEqual(mockLogManager.sentEvents.first?.name, .click)
        XCTAssertEqual(parameters?[ParameterName.screen.rawValue] as? String, "wish_search")
        XCTAssertEqual(parameters?[ParameterName.objectType.rawValue] as? String, "card")
        XCTAssertEqual(parameters?[ParameterName.objectId.rawValue] as? String, "search_result")
        XCTAssertEqual(parameters?[ParameterName.count.rawValue] as? Int, 2)
        XCTAssertEqual(parameters?[ParameterName.category.rawValue] as? String, Category.wantToGo.rawValue)
    }

    // MARK: GH-32 TC13

    func test_GH32_TC13_결과없음이보이면_search_empty노출로그가검색어당1건만전송된다() {
        // Given
        mockRepository.searchWishesResult = []
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputKeyword.send("스카이다이빙")
        viewModel.input.inputKeyword.send("스카이다이빙 ")
        viewModel.input.inputKeyword.send("번지점프")

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.map(\.name), [.impression, .impression])
        XCTAssertEqual(objectIds(of: mockLogManager.sentEvents), ["search_empty", "search_empty"])
        XCTAssertEqual(mockLogManager.sentEvents.first?.parameters[ParameterName.screen.rawValue] as? String, "wish_search")
    }
}
