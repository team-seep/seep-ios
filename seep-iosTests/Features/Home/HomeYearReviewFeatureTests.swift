import XCTest

@testable import seep_ios_dev

/// 홈 연말 회고 배너 (GH-34 R-1, R-2). 오늘 날짜는 Dependency.now 로 주입한다 (기존 HomeViewModelYearReviewTests 이전)
final class HomeYearReviewFeatureTests: HomeFeatureTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        preference = Preference(name: "test.yearReview")
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func finished(_ id: String, at finishDate: Date) -> Wish {
        Wish(id: id, title: id, finishDate: finishDate, isSuccess: true, createdAt: finishDate)
    }

    /// 콘솔에 넣을 기본 운영 값과 같은 기간 (12/1~1/31)
    private static let decemberToJanuary = YearReviewPeriod(isEnabled: true, start: .init(month: 12, day: 1), end: .init(month: 1, day: 31))

    private func makeViewModel(now: Date, period: YearReviewPeriod? = decemberToJanuary) -> HomeViewModel {
        makeSut(now: { now }, calendar: calendar, remoteConfigRepository: StubRemoteConfigRepository(period: period))
    }

    private func banner(of viewModel: HomeViewModel) -> YearReviewEligibility? {
        viewModel.state.yearReviewBanner
    }

    private func events(objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter { ($0.extraParameters?[.objectId] as? LogObjectId) == objectId }
    }

    // MARK: GH-34 TC1

    func test_GH34_TC1_12월5일에2026년완료가3개면_배너가3개로보인다() {
        // Given
        repository.fetchFinishedWishesResult = [
            finished("a", at: date(2026, 3, 1)),
            finished("b", at: date(2026, 8, 1)),
            finished("c", at: date(2026, 12, 1))
        ]
        let viewModel = makeViewModel(now: date(2026, 12, 5))

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(banner(of: viewModel)?.year, 2026)
        XCTAssertEqual(banner(of: viewModel)?.count, 3)
    }

    // MARK: GH-34 TC2

    func test_GH34_TC2_1월20일에는_지난해완료만센다() {
        // Given
        repository.fetchFinishedWishesResult = [
            finished("a", at: date(2026, 5, 1)),
            finished("b", at: date(2026, 12, 30)),
            finished("new", at: date(2027, 1, 3))
        ]
        let viewModel = makeViewModel(now: date(2027, 1, 20))

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(banner(of: viewModel)?.year, 2026)
        XCTAssertEqual(banner(of: viewModel)?.count, 2)
    }

    // MARK: GH-34 TC3

    func test_GH34_TC3_11월30일과2월1일에는_배너가없다() {
        // Given
        repository.fetchFinishedWishesResult = [
            finished("a", at: date(2026, 5, 1)),
            finished("b", at: date(2027, 1, 10))
        ]
        let november = makeViewModel(now: date(2026, 11, 30))
        let february = makeViewModel(now: date(2027, 2, 1))

        // When
        november.send(.onAppear)
        february.send(.onAppear)

        // Then
        XCTAssertNil(banner(of: november))
        XCTAssertNil(banner(of: february))
        XCTAssertTrue(events(objectId: .yearReviewBanner).isEmpty)
    }

    // MARK: GH-34 TC4

    func test_GH34_TC4_대상연도완료가0개면_12월에도배너가없다() {
        // Given
        repository.fetchFinishedWishesResult = [finished("old", at: date(2025, 12, 31))]
        let viewModel = makeViewModel(now: date(2026, 12, 10))

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertNil(banner(of: viewModel))
    }

    // MARK: GH-34 TC5

    func test_GH34_TC5_X로닫으면_같은기간에는다시뜨지않고_다음해12월에는다시뜬다() {
        // Given
        repository.fetchFinishedWishesResult = [
            finished("a", at: date(2026, 6, 1)),
            finished("b", at: date(2027, 6, 1))
        ]
        let viewModel = makeViewModel(now: date(2026, 12, 5))
        viewModel.send(.onAppear)
        XCTAssertNotNil(banner(of: viewModel))

        // When
        viewModel.send(.closeYearReviewBanner)

        // Then
        XCTAssertNil(banner(of: viewModel))
        XCTAssertEqual(preference.closedYearReviewYears, [2026])

        let sameSeason = makeViewModel(now: date(2027, 1, 15))
        sameSeason.send(.onAppear)
        XCTAssertNil(banner(of: sameSeason))

        let nextDecember = makeViewModel(now: date(2027, 12, 1))
        nextDecember.send(.onAppear)
        XCTAssertEqual(banner(of: nextDecember)?.year, 2027)
        XCTAssertEqual(banner(of: nextDecember)?.count, 1)
    }

    // MARK: GH-34 TC12

    func test_GH34_TC12_배너를탭하면_대상연도회고화면route와_배너클릭로그가나온다() {
        // Given
        repository.fetchFinishedWishesResult = [finished("a", at: date(2026, 6, 1))]
        let viewModel = makeViewModel(now: date(2026, 12, 5))
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapYearReviewBanner)

        // Then
        XCTAssertEqual(viewModel.state.yearReviewPresentation?.year, 2026)
        let clicks = events(objectId: .yearReviewBanner).filter { $0.name == .click }
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .home)
        XCTAssertEqual(clicks.first?.extraParameters?[.objectType] as? LogObjectType, .banner)
        XCTAssertEqual(clicks.first?.extraParameters?[.year] as? Int, 2026)
    }

    // MARK: GH-34 TC13

    func test_GH34_TC13_배너노출로그는_다시그려도1회만보낸다() {
        // Given
        repository.fetchFinishedWishesResult = [finished("a", at: date(2026, 6, 1))]
        let viewModel = makeViewModel(now: date(2026, 12, 5))

        // When
        viewModel.send(.onAppear)
        viewModel.send(.selectCategory(.wantToGet))
        viewModel.send(.selectCategory(.wantToGo))

        // Then
        let impressions = events(objectId: .yearReviewBanner).filter { $0.name == .impression }
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .home)
        XCTAssertEqual(impressions.first?.extraParameters?[.objectType] as? LogObjectType, .banner)
        XCTAssertNotNil(banner(of: viewModel), "카테고리를 바꿔도 같은 배너가 보인다")
    }

    func test_GH34_TC13_배너가없으면_노출로그를보내지않는다() {
        // Given
        repository.fetchFinishedWishesResult = []
        let viewModel = makeViewModel(now: date(2026, 12, 5))

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertTrue(events(objectId: .yearReviewBanner).isEmpty)
    }

    // MARK: GH-34 TC14

    func test_GH34_TC14_X를탭하면_close_year_review_banner클릭로그가1회전송된다() {
        // Given
        repository.fetchFinishedWishesResult = [finished("a", at: date(2026, 6, 1))]
        let viewModel = makeViewModel(now: date(2026, 12, 5))
        viewModel.send(.onAppear)

        // When
        viewModel.send(.closeYearReviewBanner)
        viewModel.send(.closeYearReviewBanner)

        // Then
        let clicks = events(objectId: .closeYearReviewBanner)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.name, .click)
        XCTAssertEqual(clicks.first?.screen, .home)
        XCTAssertEqual(clicks.first?.extraParameters?[.objectType] as? LogObjectType, .button)
    }

    // MARK: GH-34 TC16 (홈 배너 수 갱신)

    func test_GH34_TC16_회고화면을닫으면_홈이다시읽어_완료취소한위시가배너수에서빠진다() {
        // Given
        let wishA = finished("a", at: date(2026, 6, 1))
        let wishB = finished("b", at: date(2026, 7, 1))
        repository.fetchFinishedWishesResult = [wishA, wishB]
        let viewModel = makeViewModel(now: date(2026, 12, 5))
        viewModel.send(.onAppear)
        viewModel.send(.tapYearReviewBanner)
        XCTAssertEqual(banner(of: viewModel)?.count, 2)

        // When: 회고 → 목록 → 상세에서 b 완료 취소 후 회고를 닫는다
        repository.fetchFinishedWishesResult = [wishA]
        viewModel.send(.yearReviewDismissed)

        // Then
        XCTAssertEqual(banner(of: viewModel)?.count, 1)
        XCTAssertNil(viewModel.state.yearReviewPresentation)
    }

    // MARK: GH-34 TC19

    func test_GH34_TC19_RemoteConfig에서꺼져있으면_12월에도배너가없다() {
        // Given
        repository.fetchFinishedWishesResult = [finished("a", at: date(2026, 5, 1))]
        let disabled = YearReviewPeriod(isEnabled: false, start: .init(month: 12, day: 1), end: .init(month: 1, day: 31))
        let viewModel = makeViewModel(now: date(2026, 12, 5), period: disabled)

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertNil(banner(of: viewModel))
    }

    // MARK: GH-34 TC21

    func test_GH34_TC21_RemoteConfig기간이11월이면_11월에배너가보인다() {
        // Given
        repository.fetchFinishedWishesResult = [
            finished("a", at: date(2026, 3, 1)),
            finished("b", at: date(2026, 10, 1))
        ]
        let november = YearReviewPeriod(isEnabled: true, start: .init(month: 11, day: 1), end: .init(month: 11, day: 30))
        let viewModel = makeViewModel(now: date(2026, 11, 10), period: november)

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(banner(of: viewModel)?.year, 2026)
        XCTAssertEqual(banner(of: viewModel)?.count, 2)
    }

    // MARK: GH-34 TC22

    func test_GH34_TC22_RemoteConfig기간값이없으면_12월에도배너가없다() {
        // Given
        repository.fetchFinishedWishesResult = [finished("a", at: date(2026, 5, 1))]
        let viewModel = makeViewModel(now: date(2026, 12, 5), period: nil)

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertNil(banner(of: viewModel))
    }
}
