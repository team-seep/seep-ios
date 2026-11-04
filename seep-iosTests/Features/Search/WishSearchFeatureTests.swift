import XCTest

@testable import seep_ios

/// 위시 검색 화면 (GH-32, GH-64 TC-202·701~703)
final class WishSearchFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!

    private let now = Date()

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
    }

    override func tearDown() {
        mockRepository = nil
        super.tearDown()
    }

    private func makeViewModel(finishedOnly: Bool = false) -> WishSearchViewModel {
        WishSearchViewModel(
            config: .init(finishedOnly: finishedOnly),
            dependency: .init(wishRepository: mockRepository, logManager: logManager)
        )
    }

    private func days(_ value: Int) -> Date {
        now.addingTimeInterval(TimeInterval(value * 24 * 60 * 60))
    }

    private func objectIds(of events: [any LogEventType]) -> [String] {
        events.compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
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
        viewModel.send(.inputKeyword("제주"))

        // Then
        let sections = viewModel.state.sections
        XCTAssertEqual(sections.map(\.category), [.wantToDo, .wantToGo])
        XCTAssertEqual(sections.map { $0.items.map(\.wish.id) }, [["do"], ["go"]])
        XCTAssertEqual(viewModel.state.resultCount, 2)
        XCTAssertNil(viewModel.state.emptyKeyword)
        XCTAssertEqual(mockRepository.searchWishesCalls, ["제주"])
    }

    func test_GH32_TC1_제목에서찾은결과는_일치범위를강조한다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", category: .wantToDo, title: "한 달 제주 살기")]
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputKeyword("제주"))

        // Then
        let item = viewModel.state.sections.first?.items.first
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
        viewModel.send(.inputKeyword("제주"))

        // Then
        let item = viewModel.state.sections.first?.items.first
        XCTAssertNil(item?.titleHighlightRange)
        XCTAssertEqual(item?.memoSnippet?.text, "제주 가기 전에 사서 연습하기")
    }

    // MARK: GH-32 TC4

    func test_GH32_TC4_대소문자와앞뒤공백이달라도_다듬은검색어로찾는다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", title: "Nike 운동화")]
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputKeyword("  nike "))

        // Then
        XCTAssertEqual(mockRepository.searchWishesCalls, ["nike"])
        XCTAssertEqual(viewModel.state.sections.first?.items.first?.titleHighlightRange, NSRange(location: 0, length: 4))
    }

    // MARK: GH-32 TC5

    func test_GH32_TC5_공백만입력하면_조회하지않고_결과와안내가모두비어있다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", title: "제주")]
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputKeyword("   "))

        // Then
        XCTAssertTrue(mockRepository.searchWishesCalls.isEmpty)
        XCTAssertTrue(viewModel.state.sections.isEmpty)
        XCTAssertNil(viewModel.state.resultCount)
        XCTAssertNil(viewModel.state.emptyKeyword)
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    func test_GH32_TC5_검색어를지우면_이전결과가사라진다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", title: "제주")]
        let viewModel = makeViewModel()
        viewModel.send(.inputKeyword("제주"))

        // When
        viewModel.send(.inputKeyword(""))

        // Then
        XCTAssertTrue(viewModel.state.sections.isEmpty)
        XCTAssertNil(viewModel.state.resultCount)
    }

    // MARK: GH-32 TC6

    func test_GH32_TC6_일치하는위시가없으면_결과없음안내에검색어를넘긴다() {
        // Given
        mockRepository.searchWishesResult = []
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputKeyword(" 스카이다이빙 "))

        // Then
        XCTAssertEqual(viewModel.state.emptyKeyword, "스카이다이빙")
        XCTAssertNil(viewModel.state.resultCount)
        XCTAssertTrue(viewModel.state.sections.isEmpty)
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
        viewModel.send(.inputKeyword("제주"))

        // Then
        XCTAssertEqual(
            viewModel.state.sections.first?.items.map(\.wish.id),
            ["near", "far", "noDeadline", "finished"]
        )
    }

    // MARK: GH-32 TC8

    func test_GH32_TC8_결과를탭하면_해당위시상세로이동한다() {
        // Given
        let finished = Wish(id: "finished", category: .wantToGet, title: "제주 감귤", isSuccess: true)
        mockRepository.searchWishesResult = [Wish(id: "do", category: .wantToDo, title: "제주도"), finished]
        let viewModel = makeViewModel()
        viewModel.send(.inputKeyword("제주"))

        // When
        viewModel.send(.tapResult(IndexPath(item: 0, section: 1)))

        // Then
        XCTAssertEqual(viewModel.route, .wishDetail(id: "finished", isFinished: true))
    }

    // MARK: GH-32 TC9

    func test_GH32_TC9_상세에서위시를삭제하면_같은검색어로다시찾아_지운위시가빠진다() {
        // Given
        let target = Wish(id: "target", category: .wantToDo, title: "제주도")
        let other = Wish(id: "other", category: .wantToDo, title: "제주 맛집")
        mockRepository.searchWishesResult = [target, other]
        let viewModel = makeViewModel()
        viewModel.send(.inputKeyword("제주"))
        viewModel.send(.tapResult(IndexPath(item: 0, section: 0)))
        viewModel.send(.routeHandled)

        // When — 상세에서 지우고 돌아와 검색 화면이 다시 나타난다
        mockRepository.searchWishesResult = [other]
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(mockRepository.searchWishesCalls, ["제주", "제주"])
        XCTAssertEqual(viewModel.state.sections.first?.items.map(\.wish.id), ["other"])
        XCTAssertNil(viewModel.route)
    }

    // MARK: GH-32 TC12

    func test_GH32_TC12_결과셀을탭하면_search_result클릭로그가결과수와카테고리를담아1건전송된다() {
        // Given
        mockRepository.searchWishesResult = [
            Wish(id: "do", category: .wantToDo, title: "제주도"),
            Wish(id: "go", category: .wantToGo, title: "제주 카페")
        ]
        let viewModel = makeViewModel()
        viewModel.send(.inputKeyword("제주"))

        // When
        viewModel.send(.tapResult(IndexPath(item: 0, section: 1)))

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let parameters = logManager.sentEvents.first?.parameters
        XCTAssertEqual(logManager.sentEvents.first?.name, .click)
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
        viewModel.send(.inputKeyword("스카이다이빙"))
        viewModel.send(.inputKeyword("스카이다이빙 "))
        viewModel.send(.inputKeyword("번지점프"))

        // Then
        XCTAssertEqual(logManager.sentEvents.map(\.name), [.impression, .impression])
        XCTAssertEqual(objectIds(of: logManager.sentEvents), ["search_empty", "search_empty"])
        XCTAssertEqual(logManager.sentEvents.first?.parameters[ParameterName.screen.rawValue] as? String, "wish_search")
    }

    // MARK: GH-64 TC202

    func test_GH64_TC202_이룬싶탭에서연검색은_완료한위시만찾는다() {
        // Given
        mockRepository.searchWishesResult = [
            Wish(id: "open", category: .wantToDo, title: "여행 계획"),
            Wish(id: "done", category: .wantToGo, title: "여행 다녀오기", isSuccess: true)
        ]
        let viewModel = makeViewModel(finishedOnly: true)

        // When
        viewModel.send(.inputKeyword("여행"))

        // Then
        XCTAssertEqual(viewModel.state.sections.flatMap { $0.items.map(\.wish.id) }, ["done"])
        XCTAssertEqual(viewModel.state.resultCount, 1)
    }

    func test_GH64_TC202_완료한위시가없으면_결과없음안내가뜬다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "open", category: .wantToDo, title: "여행 계획")]
        let viewModel = makeViewModel(finishedOnly: true)

        // When
        viewModel.send(.inputKeyword("여행"))

        // Then
        XCTAssertTrue(viewModel.state.sections.isEmpty)
        XCTAssertEqual(viewModel.state.emptyKeyword, "여행")
    }

    // MARK: GH-64 TC701

    func test_GH64_TC701_제목메모해시태그에서찾은결과를_카테고리별로묶는다() {
        // Given — 저장소가 제목·메모·해시태그로 찾은 결과
        mockRepository.searchWishesResult = [
            Wish(id: "title", category: .wantToDo, title: "여행 사진 정리"),
            Wish(id: "memo", category: .wantToGet, title: "캐리어", memo: "여행 갈 때 쓰기"),
            Wish(id: "tag", category: .wantToGo, title: "오사카", hashtag: "여행")
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputKeyword("여행"))

        // Then
        let sections = viewModel.state.sections
        XCTAssertEqual(sections.map(\.category), [.wantToDo, .wantToGet, .wantToGo])
        XCTAssertNotNil(sections[0].items.first?.titleHighlightRange)
        XCTAssertNotNil(sections[1].items.first?.memoSnippet)
        XCTAssertNil(sections[2].items.first?.titleHighlightRange)
        XCTAssertNil(sections[2].items.first?.memoSnippet)
    }

    // MARK: GH-64 TC702

    func test_GH64_TC702_처음나타날때는_검색어가없어_조회하지않는다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertTrue(mockRepository.searchWishesCalls.isEmpty)
        XCTAssertEqual(viewModel.state, .init())
    }

    // MARK: GH-64 TC703

    func test_GH64_TC703_진행중위시를탭하면_진행중상세로이동하고_처리후route를비운다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", category: .wantToDo, title: "제주도")]
        let viewModel = makeViewModel()
        viewModel.send(.inputKeyword("제주"))

        // When
        viewModel.send(.tapResult(IndexPath(item: 0, section: 0)))

        // Then
        XCTAssertEqual(viewModel.route, .wishDetail(id: "do", isFinished: false))

        // When
        viewModel.send(.routeHandled)

        // Then
        XCTAssertNil(viewModel.route)
    }

    func test_GH64_TC703_없는위치를탭하면_이동하지않는다() {
        // Given
        mockRepository.searchWishesResult = [Wish(id: "do", category: .wantToDo, title: "제주도")]
        let viewModel = makeViewModel()
        viewModel.send(.inputKeyword("제주"))

        // When
        viewModel.send(.tapResult(IndexPath(item: 3, section: 2)))

        // Then
        XCTAssertNil(viewModel.route)
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }
}
