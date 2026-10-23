import XCTest

@testable import seep_ios_dev

/// 연말 회고 기간만 돌려주는 Remote Config 대역
private struct FinishedStubRemoteConfig: RemoteConfigRepository {
    let period: YearReviewPeriod?

    func fetchForceUpdateVersion() async -> Result<String, Error> {
        .success("")
    }

    func fetchAndActivate() async {}

    func fetchYearReviewPeriod() -> YearReviewPeriod? {
        period
    }
}

/// 이룬 싶 탭 (GH-64 R-17 ~ R-22)
final class FinishedFeatureTests: ViewModelTestCase {
    private var wishRepository: MockWishRepository!
    private let calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        wishRepository = MockWishRepository()
    }

    override func tearDown() {
        wishRepository = nil
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func finishedWish(
        id: String,
        category: seep_ios_dev.Category = .wantToDo,
        title: String = "위시",
        finishDate: Date,
        note: String = ""
    ) -> Wish {
        Wish(id: id, category: category, title: title, finishDate: finishDate, isSuccess: true, finishNote: note)
    }

    private func makeSut(period: YearReviewPeriod? = nil, now: Date? = nil) -> FinishedViewModel {
        let now = now ?? date(2026, 10, 22)
        return FinishedViewModel(dependency: .init(
            wishRepository: wishRepository,
            remoteConfigRepository: FinishedStubRemoteConfig(period: period),
            logManager: logManager,
            now: { now },
            calendar: calendar
        ))
    }

    private var yearReviewPeriod: YearReviewPeriod {
        YearReviewPeriod(
            isEnabled: true,
            start: YearReviewPeriod.MonthDay(month: 10, day: 1),
            end: YearReviewPeriod.MonthDay(month: 1, day: 31)
        )
    }

    // MARK: GH-64 TC7

    func test_GH64_TC7_10월2개_9월1개면_최근달부터_월별로묶는다() {
        // Given
        let wishes = [
            finishedWish(id: "sep", finishDate: date(2026, 9, 28)),
            finishedWish(id: "oct2", finishDate: date(2026, 10, 2)),
            finishedWish(id: "oct19", finishDate: date(2026, 10, 19))
        ]

        // When
        let sections = FinishedSectionBuilder.sections(finishedWishes: wishes, filter: nil, calendar: calendar)

        // Then
        XCTAssertEqual(sections.map(\.title), ["2026년 10월", "2026년 9월"])
        XCTAssertEqual(sections[0].rows.map(\.id), ["oct19", "oct2"])
        XCTAssertEqual(sections[1].rows.map(\.id), ["sep"])
    }

    func test_GH64_TC7_완료하지않은위시는_목록에넣지않는다() {
        // Given
        let wishes = [
            finishedWish(id: "done", finishDate: date(2026, 10, 2)),
            Wish(id: "todo", title: "아직", isSuccess: false)
        ]

        // When
        let sections = FinishedSectionBuilder.sections(finishedWishes: wishes, filter: nil, calendar: calendar)

        // Then
        XCTAssertEqual(sections.flatMap(\.rows).map(\.id), ["done"])
    }

    // MARK: GH-64 TC8

    func test_GH64_TC8_소감이있으면_날짜와소감을보여준다() {
        // Given
        let wish = finishedWish(id: "w", finishDate: date(2026, 10, 19), note: "생각보다 쉬웠다")

        // When
        let subtitle = FinishedSectionBuilder.subtitle(wish: wish, filter: nil, calendar: calendar)

        // Then
        XCTAssertEqual(subtitle, "19일 이룸 · “생각보다 쉬웠다”")
    }

    func test_GH64_TC8_소감이없으면_전체필터에서는카테고리_카테고리필터에서는날짜만() {
        // Given
        let wish = finishedWish(id: "w", category: .wantToGet, finishDate: date(2026, 10, 2))

        // When
        let allFilter = FinishedSectionBuilder.subtitle(wish: wish, filter: nil, calendar: calendar)
        let getFilter = FinishedSectionBuilder.subtitle(wish: wish, filter: .wantToGet, calendar: calendar)

        // Then
        XCTAssertEqual(allFilter, "2일 이룸 · 갖고 싶어요")
        XCTAssertEqual(getFilter, "2일 이룸")
    }

    // MARK: GH-64 TC9

    func test_GH64_TC9_갖고필터를누르면_갖고싶어요완료위시만보인다() {
        // Given
        wishRepository.fetchAllFinishedWishesResult = [
            finishedWish(id: "do", category: .wantToDo, finishDate: date(2026, 10, 2)),
            finishedWish(id: "get", category: .wantToGet, finishDate: date(2026, 10, 3))
        ]
        let sut = makeSut()
        sut.send(.onAppear)

        // When
        sut.send(.selectFilter(.wantToGet))

        // Then
        XCTAssertEqual(sut.state.filter, .wantToGet)
        XCTAssertEqual(sut.state.sections.flatMap(\.rows).map(\.id), ["get"])
        XCTAssertEqual(sut.state.totalCount, 2, "헤드라인 수는 필터와 상관없이 전체")
    }

    func test_GH64_TC9_고른카테고리에_이룬싶이없으면_필터빈상태다() {
        // Given
        wishRepository.fetchAllFinishedWishesResult = [
            finishedWish(id: "do", category: .wantToDo, finishDate: date(2026, 10, 2))
        ]
        let sut = makeSut()
        sut.send(.onAppear)

        // When
        sut.send(.selectFilter(.wantToGo))

        // Then
        XCTAssertTrue(sut.state.isFilteredEmpty)
        XCTAssertFalse(sut.state.isEmpty)
    }

    // MARK: GH-64 TC10

    func test_GH64_TC10_이룬싶이없으면_빈상태이고_배지는0개다() {
        // Given
        wishRepository.fetchAllFinishedWishesResult = []
        let sut = makeSut()

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertTrue(sut.state.isEmpty)
        XCTAssertEqual(sut.state.earnedBadgeCount, 0)
        XCTAssertTrue(sut.state.recentBadges.isEmpty)
    }

    func test_GH64_TC10_배지카드는_최근얻은배지부터_최대5개다() {
        // Given: 5개 완료 → finish1·finish5·첫 하고·첫 갖고·첫 가고 = 5개 획득
        wishRepository.fetchAllFinishedWishesResult = [
            finishedWish(id: "1", category: .wantToDo, finishDate: date(2026, 9, 1)),
            finishedWish(id: "2", category: .wantToGet, finishDate: date(2026, 9, 2)),
            finishedWish(id: "3", category: .wantToGo, finishDate: date(2026, 9, 3)),
            finishedWish(id: "4", category: .wantToDo, finishDate: date(2026, 9, 4)),
            finishedWish(id: "5", category: .wantToDo, finishDate: date(2026, 9, 5))
        ]
        let sut = makeSut()

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(sut.state.earnedBadgeCount, 5)
        XCTAssertEqual(sut.state.recentBadges.count, 5)
        XCTAssertEqual(sut.state.recentBadges.first, .finish5)
    }

    // MARK: GH-64 TC11

    func test_GH64_TC11_회고기간이아니면_회고카드가없다() {
        // Given
        wishRepository.fetchAllFinishedWishesResult = [finishedWish(id: "w", finishDate: date(2026, 3, 1))]
        wishRepository.fetchFinishedWishesResult = wishRepository.fetchAllFinishedWishesResult
        let sut = makeSut(period: nil)

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertNil(sut.state.yearReview)
    }

    func test_GH64_TC11_회고기간이고올해이룬싶이있으면_카드가있고누르면회고를연다() {
        // Given
        let wishes = (1...3).map { finishedWish(id: "\($0)", finishDate: date(2026, 3, $0)) }
        wishRepository.fetchAllFinishedWishesResult = wishes
        wishRepository.fetchFinishedWishesResult = wishes
        let sut = makeSut(period: yearReviewPeriod)
        sut.send(.onAppear)

        // When
        sut.send(.tapYearReview)

        // Then
        XCTAssertEqual(sut.state.yearReview, YearReviewEligibility(year: 2026, count: 3))
        XCTAssertEqual(sut.route, .yearReview(year: 2026))
        XCTAssertEqual(clickEvents(objectId: .yearReviewCard).count, 1)
    }

    // MARK: GH-64 TC13

    func test_GH64_TC13_모아보기를누르면_배지모아보기로가고_로그가1건간다() {
        // Given
        let sut = makeSut()
        sut.send(.onAppear)

        // When
        sut.send(.tapBadgeCollection)

        // Then
        XCTAssertEqual(sut.route, .push(.badgeCollection))
        let events = clickEvents(objectId: .badgeCollection)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .finished)
    }

    func test_GH64_TC13_셀을누르면_완료모드상세로간다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapWish(id: "w1"))

        // Then
        XCTAssertEqual(sut.route, .push(.wishDetail(id: "w1", isFinished: true)))

        // When
        sut.send(.routeHandled)

        // Then
        XCTAssertNil(sut.route)
    }

    // MARK: GH-64 TC202

    func test_GH64_TC202_이룬싶탭검색은_완료한위시만찾는다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapSearch)

        // Then
        XCTAssertEqual(sut.route, .push(.search(finishedOnly: true)))
    }

    // MARK: GH-64 TC203

    func test_GH64_TC203_다른곳에서완료상태가바뀌면_다시보일때목록과수가갱신된다() {
        // Given
        let first = finishedWish(id: "a", finishDate: date(2026, 10, 1))
        wishRepository.fetchAllFinishedWishesResult = [first]
        let sut = makeSut()
        sut.send(.onAppear)
        XCTAssertEqual(sut.state.totalCount, 1)

        // When: 위젯에서 하나 더 완료, 상세에서 a 완료 취소
        wishRepository.fetchAllFinishedWishesResult = [
            finishedWish(id: "b", finishDate: date(2026, 10, 5)),
            finishedWish(id: "c", finishDate: date(2026, 10, 6))
        ]
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(sut.state.totalCount, 2)
        XCTAssertEqual(sut.state.sections.flatMap(\.rows).map(\.id), ["c", "b"])
    }

    // MARK: GH-64 TC204

    func test_GH64_TC204_탭이다시보여도_finished페이지뷰는1건이다() {
        // Given
        let sut = makeSut()
        let tracker = ScreenTracker()

        // When
        tracker.trackIfNeeded(screen: sut.screenName, logManager: logManager)
        tracker.trackIfNeeded(screen: sut.screenName, logManager: logManager)

        // Then
        XCTAssertEqual(logManager.pageViews.map(\.screen), [.finished])
    }
}
