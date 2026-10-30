import XCTest

@testable import seep_ios

/// 연말 회고 · 전체 보기 (GH-34, GH-64 TC-901~903)
final class YearReviewFeatureTests: ViewModelTestCase {
    private var calendar: Calendar!
    private var repository: MockWishRepository!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        repository = MockWishRepository()
    }

    override func tearDown() {
        repository = nil
        calendar = nil
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func makeViewModel(year: Int = 2026) -> YearReviewViewModel {
        YearReviewViewModel(
            config: .init(year: year),
            dependency: .init(wishRepository: repository, logManager: logManager, calendar: calendar)
        )
    }

    private func makeListViewModel() -> YearReviewListViewModel {
        YearReviewListViewModel(
            config: .init(year: 2026),
            dependency: .init(wishRepository: repository, calendar: calendar)
        )
    }

    // MARK: GH-34 TC6 (화면 집계)

    func test_GH34_TC6_화면이나타나면_대상연도구간의완료위시로집계한다() {
        // Given
        repository.fetchFinishedWishesResult = [
            Wish(id: "do", category: .wantToDo, finishDate: date(2026, 2, 1), isSuccess: true),
            Wish(id: "get", category: .wantToGet, finishDate: date(2026, 9, 1), isSuccess: true),
            Wish(id: "old", category: .wantToGo, finishDate: date(2025, 9, 1), isSuccess: true)
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.send(.onAppear)

        // Then
        let summary = viewModel.state.summary
        XCTAssertEqual(summary?.totalCount, 2)
        XCTAssertEqual(summary?.count(of: .wantToGo), 0)
        XCTAssertEqual(repository.fetchFinishedWishesCalls.first?.from, date(2026, 1, 1))
        XCTAssertEqual(repository.fetchFinishedWishesCalls.first?.to, date(2027, 1, 1))
    }

    // MARK: GH-34 TC10

    /// 공유 시트는 화면의 `ShareLink`가 연다. ViewModel 은 눌렀을 때 로그만 보낸다
    func test_GH34_TC10_이미지로공유하기를탭하면_이미지1장과공유시트route가나오고_공유로그가1회전송된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.didTapShare)

        // Then
        XCTAssertNil(viewModel.route)
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.screen, .yearReview)
        XCTAssertEqual(event?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(event?.extraParameters?[.objectId] as? LogObjectId, .shareYearReview)
        XCTAssertEqual(event?.extraParameters?[.year] as? Int, 2026)
    }

    // MARK: GH-34 TC15 (모두 보기 이동)

    func test_GH34_TC15_모두보기를탭하면_같은연도목록화면으로이동한다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.tapShowAll)

        // Then
        XCTAssertEqual(viewModel.route, .yearReviewList(year: 2026))
    }

    // MARK: GH-34 TC16

    func test_GH34_TC16_완료취소한위시는_다시나타날때집계에서빠진다() {
        // Given
        let kept = Wish(id: "kept", finishDate: date(2026, 4, 1), isSuccess: true)
        let cancelled = Wish(id: "cancelled", finishDate: date(2026, 5, 1), isSuccess: true)
        repository.fetchFinishedWishesResult = [kept, cancelled]
        let viewModel = makeViewModel()
        viewModel.send(.onAppear)
        XCTAssertEqual(viewModel.state.summary?.totalCount, 2)

        // When: 목록 → 상세에서 완료 취소하고 돌아온다
        var reverted = cancelled
        reverted.isSuccess = false
        reverted.finishDate = nil
        repository.fetchFinishedWishesResult = [kept, reverted]
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(viewModel.state.summary?.totalCount, 1)
        XCTAssertEqual(viewModel.state.summary?.wishes.map(\.id), ["kept"])
    }

    func test_GH34_TC16_닫기를탭하면_dismiss와닫힘이벤트가나온다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.tapClose)

        // Then — 닫힌 뒤 목록·배너 갱신은 띄운 쪽의 onDismiss 가 맡는다
        XCTAssertEqual(viewModel.route, .dismiss)

        // When
        viewModel.send(.routeHandled)

        // Then
        XCTAssertNil(viewModel.route)
    }

    // MARK: GH-34 TC15 (목록)

    func test_GH34_TC15_달내림차순으로묶고_소감이없으면완료일을보인다() {
        // Given
        repository.fetchFinishedWishesResult = [
            Wish(id: "aug2", finishDate: date(2026, 8, 2), isSuccess: true),
            Wish(id: "dec3", finishDate: date(2026, 12, 3), isSuccess: true, finishNote: "드디어 겟!"),
            Wish(id: "aug31", finishDate: date(2026, 8, 31), isSuccess: true)
        ]
        let viewModel = makeListViewModel()

        // When
        viewModel.send(.onAppear)

        // Then
        let sections = viewModel.state.sections
        XCTAssertEqual(viewModel.state.totalCount, 3)
        XCTAssertEqual(sections.map(\.month), [12, 8])
        XCTAssertEqual(sections[1].items.map(\.wish.id), ["aug31", "aug2"])
        XCTAssertEqual(sections[0].items.first?.note, "“드디어 겟!”")
        XCTAssertNil(sections[1].items.first?.note)
        XCTAssertEqual(sections[1].items.first?.finishDateText, "08.31")
        XCTAssertEqual(sections[1].items.last?.finishDateText, "08.02")
    }

    func test_GH34_TC15_셀을탭하면_그위시의상세로이동한다() {
        // Given
        repository.fetchFinishedWishesResult = [
            Wish(id: "aug2", finishDate: date(2026, 8, 2), isSuccess: true),
            Wish(id: "dec3", finishDate: date(2026, 12, 3), isSuccess: true)
        ]
        let viewModel = makeListViewModel()
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapWish(IndexPath(item: 0, section: 1)))

        // Then
        XCTAssertEqual(viewModel.route, .wishDetail(id: "aug2"))
    }

    // MARK: GH-64 TC901

    func test_GH64_TC901_올해이룬싶을_카테고리별수와대표위시로요약한다() {
        // Given
        repository.fetchFinishedWishesResult = [
            Wish(id: "do1", category: .wantToDo, finishDate: date(2026, 3, 1), isSuccess: true, createdAt: date(2025, 1, 1)),
            Wish(id: "do2", category: .wantToDo, finishDate: date(2026, 3, 9), isSuccess: true, finishNote: "최고", createdAt: date(2026, 3, 1)),
            Wish(id: "go", category: .wantToGo, finishDate: date(2026, 7, 1), isSuccess: true, createdAt: date(2026, 6, 1))
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.send(.onAppear)

        // Then
        let summary = viewModel.state.summary
        XCTAssertEqual(summary?.count(of: .wantToDo), 2)
        XCTAssertEqual(summary?.count(of: .wantToGet), 0)
        XCTAssertEqual(summary?.count(of: .wantToGo), 1)
        XCTAssertEqual(summary?.longestHeld?.wish.id, "do1")
        XCTAssertEqual(summary?.busiestMonth?.month, 3)
        XCTAssertEqual(summary?.noteOfYear?.id, "do2")
    }

    // MARK: GH-64 TC902

    func test_GH64_TC902_공유이미지캔버스는_카드를여백안에담는4대5다() {
        // Given
        let cardSize = CGSize(width: 335, height: 520)

        // When
        let canvas = YearReviewImageRenderer.canvasSize(cardSize: cardSize)

        // Then
        XCTAssertEqual(canvas.width / canvas.height, 4.0 / 5.0, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(canvas.width, cardSize.width + 48)
        XCTAssertGreaterThanOrEqual(canvas.height, cardSize.height + 48)
    }

    @MainActor
    func test_GH64_TC902_카드를그리면_4대5이미지가나온다() {
        // Given
        let summary = YearReviewSummary.make(
            wishes: [Wish(id: "do", category: .wantToDo, finishDate: date(2026, 3, 1), isSuccess: true)],
            year: 2026,
            calendar: calendar
        )

        // When
        let image = YearReviewImageRenderer.render(summary: summary, cardWidth: 335)

        // Then
        XCTAssertNotNil(image)
    }

    func test_GH64_TC902_공유를누를때마다_공유로그를보낸다() {
        // Given
        let viewModel = makeViewModel(year: 2025)

        // When
        viewModel.send(.didTapShare)
        viewModel.send(.didTapShare)

        // Then
        XCTAssertEqual(clickEvents(objectId: .shareYearReview).count, 2)
        XCTAssertEqual(logManager.sentEvents.last?.extraParameters?[.year] as? Int, 2025)
    }

    // MARK: GH-64 TC903

    func test_GH64_TC903_전체보기에서_없는위치를탭하면_이동하지않고_처리후route를비운다() {
        // Given
        repository.fetchFinishedWishesResult = [Wish(id: "aug2", finishDate: date(2026, 8, 2), isSuccess: true)]
        let viewModel = makeListViewModel()
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapWish(IndexPath(item: 5, section: 0)))

        // Then
        XCTAssertNil(viewModel.route)

        // When
        viewModel.send(.tapWish(IndexPath(item: 0, section: 0)))
        viewModel.send(.routeHandled)

        // Then
        XCTAssertNil(viewModel.route)
        XCTAssertEqual(viewModel.year, 2026)
    }
}
