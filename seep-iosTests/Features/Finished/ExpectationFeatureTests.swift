import XCTest

@testable import seep_ios

/// 연말 회고를 끈 Remote Config 대역
private struct ExpectationStubRemoteConfig: RemoteConfigRepository {
    func fetchForceUpdateVersion() async -> Result<String, Error> { .success("") }
    func fetchAndActivate() async {}
    func fetchYearReviewPeriod() -> YearReviewPeriod? { nil }
    func fetchLegacyRealmReimportToken() -> String { "" }
    func fetchSyncEnabled() -> Bool { false }
}

/// 이룬 싶 탭 "이뤄 보니 n개가 기대보다 좋았어요" 요약 카드·모아 보기, 목록·상세 문구 (GH-139 R-6 ~ R-8)
final class ExpectationFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private let calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    private func date(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)) ?? Date()
    }

    private func finished(
        _ id: String,
        _ category: seep_ios.Category = .wantToDo,
        _ feeling: FinishFeeling? = nil,
        note: String = "",
        day: Int = 1
    ) -> Wish {
        Wish(id: id, category: category, title: id, finishDate: date(11, day), isSuccess: true, finishNote: note, finishFeeling: feeling)
    }

    private func makeSut(_ wishes: [Wish]) -> FinishedViewModel {
        repository.fetchAllFinishedWishesResult = wishes
        let now = date(11, 27)
        return FinishedViewModel(dependency: .init(
            wishRepository: repository,
            remoteConfigRepository: ExpectationStubRemoteConfig(),
            logManager: logManager,
            now: { now },
            calendar: calendar
        ))
    }

    /// 하고 싶어요 better 2·same 1, 갖고 싶어요 worse 1 + 기록 없는 2개 = 이룬 싶 6개 (TC-7)
    private var sixWishes: [Wish] {
        [
            finished("do-better-1", .wantToDo, .better, day: 1),
            finished("do-better-2", .wantToDo, .better, day: 2),
            finished("do-same", .wantToDo, .same, day: 3),
            finished("get-worse", .wantToGet, .worse, day: 4),
            finished("get-none", .wantToGet, day: 5),
            finished("go-none", .wantToGo, day: 6)
        ]
    }

    private func listedIds(_ sut: FinishedViewModel) -> [String] {
        sut.state.sections.flatMap(\.rows).map(\.id)
    }

    private func events(_ name: EventName, objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter {
            $0.name == name && $0.parameters[ParameterName.objectId.rawValue] as? String == objectId.rawValue
        }
    }

    // MARK: GH-139 TC7

    func test_GH139_TC7_기록한싶이하고better2same1_갖고worse1이면_요약은2개_막대는2of3_0of1_0of0이다() {
        // Given
        let sut = makeSut(sixWishes)

        // When
        sut.send(.onAppear)

        // Then
        let summary = sut.state.expectationSummary
        XCTAssertEqual(summary?.betterCount, 2)
        XCTAssertEqual(summary?.recordedCount, 4)
        XCTAssertEqual(summary?.rows.map(\.category), [.wantToDo, .wantToGet, .wantToGo])
        XCTAssertEqual(summary?.rows.map(\.betterCount), [2, 0, 0])
        XCTAssertEqual(summary?.rows.map(\.recordedCount), [3, 1, 0])
        XCTAssertEqual(summary?.rows.last?.ratio, 0)
        XCTAssertEqual(Strings.Finished.Expectation.titleFormat(2), "이뤄 보니 2개가 기대보다 좋았어요")
        XCTAssertEqual(Strings.Finished.Expectation.captionFormat(4), "기대랑 비교해 본 싶 4개 기준")
        XCTAssertEqual(Strings.Finished.Expectation.noRecord, "기록 없음")
    }

    // MARK: GH-139 TC8

    func test_GH139_TC8_기대비교를남긴싶이2개면_요약카드가없다() {
        // Given
        let sut = makeSut([
            finished("a", .wantToDo, .better),
            finished("b", .wantToGo, .worse),
            finished("c", .wantToGet)
        ])

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertNil(sut.state.expectationSummary)
    }

    func test_GH139_TC8_기대비교를남긴싶이3개면_요약카드가보인다() {
        // Given
        let sut = makeSut([
            finished("a", .wantToDo, .better),
            finished("b", .wantToGo, .worse),
            finished("c", .wantToGet, .same)
        ])

        // When
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(sut.state.expectationSummary?.betterCount, 1)
    }

    // MARK: GH-139 TC9

    func test_GH139_TC9_모아보기를누르면_better인싶만남고_다시누르면풀린다() {
        // Given
        let sut = makeSut(sixWishes)
        sut.send(.onAppear)

        // When
        sut.send(.tapExpectationBetterFilter)

        // Then
        XCTAssertTrue(sut.state.isBetterFilterOn)
        XCTAssertEqual(Set(listedIds(sut)), ["do-better-1", "do-better-2"])

        // When
        sut.send(.tapExpectationBetterFilter)

        // Then
        XCTAssertFalse(sut.state.isBetterFilterOn)
        XCTAssertEqual(listedIds(sut).count, 6)
    }

    func test_GH139_TC9_모아보기는카테고리필터와함께걸리고_카테고리를바꾸면풀린다() {
        // Given
        let sut = makeSut(sixWishes + [finished("go-better", .wantToGo, .better, day: 7)])
        sut.send(.onAppear)
        sut.send(.selectFilter(.wantToDo))

        // When: 하고 싶어요를 고른 채 모아 보기
        sut.send(.tapExpectationBetterFilter)

        // Then
        XCTAssertEqual(Set(listedIds(sut)), ["do-better-1", "do-better-2"])

        // When: 카테고리를 바꾼다
        sut.send(.selectFilter(.wantToGo))

        // Then
        XCTAssertFalse(sut.state.isBetterFilterOn)
        XCTAssertEqual(Set(listedIds(sut)), ["go-none", "go-better"])
    }

    func test_GH139_TC9_모아보기중고른카테고리에better가없으면_빈목록이다() {
        // Given
        let sut = makeSut(sixWishes)
        sut.send(.onAppear)

        // When: 모아 보기를 켠 뒤에는 카테고리를 바꾸면 풀리므로, 갖고 싶어요를 먼저 고르고 켠다
        sut.send(.selectFilter(.wantToGet))
        sut.send(.tapExpectationBetterFilter)

        // Then
        XCTAssertTrue(sut.state.isFilteredEmpty)
        XCTAssertEqual(Strings.Finished.Empty.betterFiltered, "기대보다 좋았던 싶이 아직 없어요")
    }

    func test_GH139_TC9_다시읽어카드가사라지면_모아보기도풀린다() {
        // Given
        let sut = makeSut(sixWishes)
        sut.send(.onAppear)
        sut.send(.tapExpectationBetterFilter)

        // When: 다른 곳에서 완료를 취소해 기록이 2개만 남는다
        repository.fetchAllFinishedWishesResult = [finished("a", .wantToDo, .better), finished("b", .wantToDo, .same)]
        sut.send(.onAppear)

        // Then
        XCTAssertNil(sut.state.expectationSummary)
        XCTAssertFalse(sut.state.isBetterFilterOn)
        XCTAssertEqual(listedIds(sut).count, 2)
    }

    // MARK: GH-139 TC12

    func test_GH139_TC12_요약카드가보이면_expectation_summary노출이화면당1건간다() {
        // Given
        let sut = makeSut(sixWishes)
        sut.send(.onAppear)

        // When
        sut.send(.expectationSummaryAppeared)
        sut.send(.onAppear)
        sut.send(.expectationSummaryAppeared)

        // Then
        let impressions = events(.impression, objectId: .expectationSummary)
        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.screen, .finished)
        XCTAssertEqual(impressions.first?.parameters[ParameterName.objectType.rawValue] as? String, "card")
    }

    func test_GH139_TC12_모아보기를누르면_expectation_better_filter클릭이1건간다() {
        // Given
        let sut = makeSut(sixWishes)
        sut.send(.onAppear)

        // When: 켜고 끈다
        sut.send(.tapExpectationBetterFilter)
        sut.send(.tapExpectationBetterFilter)

        // Then: 켤 때만 센다
        let clicks = events(.click, objectId: .expectationBetterFilter)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .finished)
        XCTAssertEqual(clicks.first?.parameters[ParameterName.objectType.rawValue] as? String, "button")
    }

    func test_GH139_TC12_카드가없으면_노출을보내지않는다() {
        // Given
        let sut = makeSut([finished("a", .wantToDo, .better)])
        sut.send(.onAppear)

        // When
        sut.send(.expectationSummaryAppeared)

        // Then
        XCTAssertTrue(events(.impression, objectId: .expectationSummary).isEmpty)
    }

    // MARK: GH-139 TC15

    func test_GH139_TC15_이룬싶목록셀은_기대비교를소감앞에붙인다() {
        // Given
        let withNote = finished("a", .wantToDo, .better, note: "최고", day: 3)
        let feelingOnly = finished("b", .wantToDo, .same, day: 3)
        let noteOnly = finished("c", .wantToDo, note: "좋았다", day: 3)

        // When
        let subtitles = [withNote, feelingOnly, noteOnly].map {
            FinishedSectionBuilder.subtitle(wish: $0, filter: nil, calendar: calendar)
        }

        // Then
        XCTAssertEqual(subtitles, [
            "3일 이룸 · 기대보다 좋았어요 · “최고”",
            "3일 이룸 · 딱 기대만큼",
            "3일 이룸 · “좋았다”"
        ])
    }

    func test_GH139_TC15_상세이어지는싶캡션은_기대비교를소감앞에붙인다() {
        // Given
        let finishDate = date(10, 24)
        let withNote = Wish(id: "a", title: "올레길", finishDate: finishDate, isSuccess: true, finishNote: "최고", finishFeeling: .better)
        let feelingOnly = Wish(id: "b", title: "한라산", finishDate: finishDate, isSuccess: true, finishFeeling: .worse, previousWishId: "a")
        let current = Wish(id: "c", title: "우도", previousWishId: "b")

        // When
        let rows = DetailChainRow.rows(chain: WishChain(previous: [withNote, feelingOnly], current: current, next: []))

        // Then
        let dateText = DisplayDate.numericYearMonthDay(finishDate)
        XCTAssertEqual(rows.map(\.caption), [
            "\(dateText) 이뤘어요 · 기대보다 좋았어요 · “최고”",
            "\(dateText) 이뤘어요 · 기대보다 아쉬웠어요",
            "지금 이 싶"
        ])
    }
}
