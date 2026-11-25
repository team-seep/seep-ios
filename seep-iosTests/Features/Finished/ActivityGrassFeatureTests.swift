import XCTest

@testable import seep_ios

/// 이룬 싶 탭 "싶에 다가간 날" 잔디 (GH-146 R-1~R-9)
final class ActivityGrassFeatureTests: ViewModelTestCase {
    private var wishRepository: MockWishRepository!
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        // 일요일부터 (기기 달력을 따르는지 고정해서 본다)
        calendar.firstWeekday = 1
        return calendar
    }()
    private lazy var today = date(2026, 11, 18, hour: 21)

    override func setUp() {
        super.setUp()
        wishRepository = MockWishRepository()
    }

    override func tearDown() {
        wishRepository = nil
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? Date()
    }

    private func activity(
        _ id: String,
        wishId: String = "wish-1",
        kind: WishActivity.Kind = .added,
        date: Date,
        isWishFinished: Bool = false
    ) -> WishActivity {
        WishActivity(id: id, wishId: wishId, emoji: "🏃", wishTitle: "위시 \(wishId)", isWishFinished: isWishFinished, kind: kind, date: date)
    }

    private func makeSut() -> FinishedViewModel {
        FinishedViewModel(dependency: .init(
            wishRepository: wishRepository,
            remoteConfigRepository: ActivityStubRemoteConfig(),
            logManager: logManager,
            now: { [today] in today },
            calendar: calendar
        ))
    }

    private func events(name: EventName, objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter { event in
            event.name == name && (event.extraParameters?[.objectId] as? LogObjectId) == objectId
        }
    }

    // MARK: TC-1

    func test_GH146_TC1_오늘행동2건이면_오늘칸은2단계이고_올해1일이다() throws {
        // Given: 오늘 싶 1개를 담고 단계 1개를 체크했다
        wishRepository.fetchActivitiesResult = [
            activity("added-1", date: date(2026, 11, 18, hour: 9)),
            activity("step-1", kind: .stepDone(stepTitle: "항공권"), date: date(2026, 11, 18, hour: 10))
        ]
        let sut = makeSut()

        // When
        sut.send(.onAppear)

        // Then
        let grass = try XCTUnwrap(sut.state.grass)
        let lastWeek = try XCTUnwrap(grass.weeks.last)
        let todayCell = try XCTUnwrap(lastWeek.first { $0.date == calendar.startOfDay(for: today) })
        XCTAssertEqual(todayCell.level, 2)
        XCTAssertEqual(grass.yearDayCount, 1)
        // 오늘(수요일) 뒤 칸은 비워 둔다
        XCTAssertEqual(lastWeek.filter(\.isFuture).count, 3)
        XCTAssertEqual(grass.weeks.count, ActivityGrass.maxWeeks)
        XCTAssertTrue(grass.weeks.allSatisfy { calendar.component(.weekday, from: $0[0].date) == 1 })
    }

    // MARK: TC-5

    func test_GH146_TC5_하루행동이5건이면_4단계다() {
        // Given / When / Then
        XCTAssertEqual(ActivityGrass.level(count: 0), 0)
        XCTAssertEqual(ActivityGrass.level(count: 1), 1)
        XCTAssertEqual(ActivityGrass.level(count: 3), 3)
        XCTAssertEqual(ActivityGrass.level(count: 4), 4)
        XCTAssertEqual(ActivityGrass.level(count: 5), 4)
    }

    // MARK: TC-6

    func test_GH146_TC6_행동3건인날칸을누르면_시트에3줄이시간순으로나오고_activity_day로그가남는다() throws {
        // Given: 이룸(자정 저장)·모은 돈(자정 저장)·담음(오후)
        let day = date(2026, 11, 10)
        let midnight = calendar.startOfDay(for: day)
        wishRepository.fetchActivitiesResult = [
            activity("added-3", wishId: "w3", kind: .added, date: date(2026, 11, 10, hour: 15)),
            activity("finished-1", wishId: "w1", kind: .finished, date: midnight, isWishFinished: true),
            activity("saving-2", wishId: "w2", kind: .saving(amount: 30_000, currency: "KRW"), date: midnight),
            activity("added-x", wishId: "w4", date: date(2026, 11, 11))
        ]
        let sut = makeSut()
        sut.send(.onAppear)

        // When
        sut.send(.tapGrassDay(day))

        // Then
        let sheet = try XCTUnwrap(sut.state.activityDay)
        XCTAssertEqual(sheet.date, midnight)
        // 모은 돈·이룸은 날짜만 저장해 그날 시각이 있는 행동 뒤에, 모은 돈 → 이룸 순서로 둔다
        XCTAssertEqual(sheet.activities.map(\.id), ["added-3", "saving-2", "finished-1"])
        let headline = Strings.Finished.ActivityDay.headlineFormat("11월 10일 (화)", sheet.activities.count)
        XCTAssertEqual(headline, "11월 10일 (화),\n싶에 3번 다가갔어요")
        XCTAssertTrue(headline.contains(Strings.Finished.ActivityDay.countBoldFormat(3)))
        XCTAssertEqual(sheet.activities.map(\.subtitle), [
            "담았어요",
            Strings.Finished.ActivityDay.savingFormat(AmountFormatter.money(30_000, currency: "KRW")),
            "이뤘어요!"
        ])
        let logs = events(name: .click, objectId: .activityDay)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.parameters["screen"] as? String, "finished")
        XCTAssertEqual(logs.first?.parameters["object_type"] as? String, "card")
        XCTAssertEqual(logs.first?.parameters["count"] as? Int, 3)
    }

    func test_GH146_TC6_행동이없는날칸을누르면_빈시트가열리고_count0로그가남는다() throws {
        // Given
        wishRepository.fetchActivitiesResult = [activity("added-1", date: date(2026, 11, 11))]
        let sut = makeSut()
        sut.send(.onAppear)

        // When
        sut.send(.tapGrassDay(date(2026, 11, 12)))

        // Then
        XCTAssertEqual(sut.state.activityDay?.activities, [])
        XCTAssertEqual(events(name: .click, objectId: .activityDay).first?.parameters["count"] as? Int, 0)
    }

    // MARK: TC-7

    func test_GH146_TC7_시트의줄을누르면_시트가닫히고그위시상세로간다() throws {
        // Given
        let finished = activity("finished-1", wishId: "w1", kind: .finished, date: date(2026, 11, 10), isWishFinished: true)
        let journal = activity("journal-2", wishId: "w2", kind: .journal, date: date(2026, 11, 10, hour: 13))
        wishRepository.fetchActivitiesResult = [finished, journal]
        let sut = makeSut()
        sut.send(.onAppear)
        sut.send(.tapGrassDay(date(2026, 11, 10)))

        // When
        sut.send(.tapActivityWish(journal))

        // Then
        XCTAssertNil(sut.state.activityDay)
        XCTAssertEqual(sut.route, .push(.wishDetail(id: "w2", isFinished: false)))

        // 이룬 위시면 이룬 상세로 연다
        sut.send(.routeHandled)
        sut.send(.tapGrassDay(date(2026, 11, 10)))
        sut.send(.tapActivityWish(finished))
        XCTAssertEqual(sut.route, .push(.wishDetail(id: "w1", isFinished: true)))
    }

    // MARK: TC-8

    func test_GH146_TC8_행동이하나도없는새사용자는_카드가보이지않는다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.onAppear)
        sut.send(.grassAppeared)

        // Then
        XCTAssertNil(sut.state.grass)
        XCTAssertTrue(events(name: .impression, objectId: .activityGrass).isEmpty)
        // 조회 범위는 26주 전 주 첫날(올해 1월 1일보다 이르면 그날)부터 내일 0시까지
        let call = try? XCTUnwrap(wishRepository.fetchActivitiesCalls.first)
        XCTAssertEqual(call?.from, date(2026, 1, 1, hour: 0))
        XCTAssertEqual(call?.to, date(2026, 11, 19, hour: 0))
    }

    // MARK: TC-13

    func test_GH146_TC13_잔디카드가여러번보여도_activity_grass노출로그는화면당1건이다() {
        // Given
        wishRepository.fetchActivitiesResult = [activity("added-1", date: date(2026, 11, 1))]
        let sut = makeSut()
        sut.send(.onAppear)

        // When: 탭을 오가며 카드가 다시 보인다
        sut.send(.grassAppeared)
        sut.send(.onAppear)
        sut.send(.grassAppeared)

        // Then
        let logs = events(name: .impression, objectId: .activityGrass)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.parameters["screen"] as? String, "finished")
        XCTAssertEqual(logs.first?.parameters["object_type"] as? String, "card")
    }

    // MARK: TC-14

    func test_GH146_TC14_시트의줄을누르면_activity_day_wish클릭로그가1건남는다() {
        // Given
        let added = activity("added-1", date: date(2026, 11, 10))
        wishRepository.fetchActivitiesResult = [added]
        let sut = makeSut()
        sut.send(.onAppear)
        sut.send(.tapGrassDay(date(2026, 11, 10)))

        // When
        sut.send(.tapActivityWish(added))

        // Then
        let logs = clickEvents(objectId: .activityDayWish)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.parameters["screen"] as? String, "finished")
        XCTAssertEqual(logs.first?.parameters["object_type"] as? String, "button")
    }

    // MARK: TC-16

    func test_GH146_TC16_작년12월과올해1월행동이있으면_올해n일은올해날만센다() throws {
        // Given: 1월 5일이 오늘이면 잔디 26주에 작년 12월도 들어간다
        today = date(2026, 1, 5, hour: 9)
        wishRepository.fetchActivitiesResult = [
            activity("a", date: date(2025, 12, 20)),
            activity("b", date: date(2025, 12, 31)),
            activity("c", date: date(2026, 1, 2)),
            activity("d", date: date(2026, 1, 2, hour: 18)),
            activity("e", date: date(2026, 1, 4))
        ]
        let sut = makeSut()

        // When
        sut.send(.onAppear)

        // Then
        let grass = try XCTUnwrap(sut.state.grass)
        XCTAssertEqual(grass.yearDayCount, 2)
        XCTAssertEqual(grass.activeDayCount(inLast: 18), 4)
    }

    // MARK: TC-17

    func test_GH146_TC17_카드안쪽너비에따라_아이폰은18주_넓은화면은최대26주다() {
        // Given / When / Then: 칸 14 + 간격 3
        XCTAssertEqual(ActivityGrass.visibleWeekCount(contentWidth: 0), 18)     // 너비를 재기 전
        XCTAssertEqual(ActivityGrass.visibleWeekCount(contentWidth: 252), 15)   // 320pt(디스플레이 확대) — 카드를 넘지 않는다
        XCTAssertEqual(ActivityGrass.visibleWeekCount(contentWidth: 307), 18)   // iPhone SE·mini
        XCTAssertEqual(ActivityGrass.visibleWeekCount(contentWidth: 334), 19)   // 402pt 아이폰
        XCTAssertEqual(ActivityGrass.visibleWeekCount(contentWidth: 439), 26)
        XCTAssertEqual(ActivityGrass.visibleWeekCount(contentWidth: 532), 26)   // 기둥 600
    }

    func test_GH146_TC17_보이는주수만큼_최근주만보여주고_월라벨은1일이든주위에둔다() throws {
        // Given
        wishRepository.fetchActivitiesResult = [activity("a", date: date(2026, 11, 1))]
        let sut = makeSut()
        sut.send(.onAppear)
        let grass = try XCTUnwrap(sut.state.grass)

        // When
        let visible = grass.visibleWeeks(18)
        let labels = grass.monthLabels(inLast: 18, calendar: calendar)

        // Then
        XCTAssertEqual(visible.count, 18)
        XCTAssertEqual(visible.last, grass.weeks.last)
        XCTAssertEqual(labels.map { calendar.component(.month, from: $0.monthStart) }, [8, 9, 10, 11])
        XCTAssertTrue(labels.allSatisfy { $0.column < visible.count - 1 })
        for label in labels {
            XCTAssertTrue(visible[label.column].contains { $0.date == label.monthStart })
        }
    }

    // MARK: TC-18

    func test_GH146_TC18_VoiceOver_칸은날짜와횟수_카드는최근18주중n일로읽는다() throws {
        // Given
        wishRepository.fetchActivitiesResult = [
            activity("a", date: date(2026, 11, 17)),
            activity("b", date: date(2026, 11, 17, hour: 13)),
            activity("c", date: date(2026, 11, 3))
        ]
        let sut = makeSut()
        sut.send(.onAppear)
        let grass = try XCTUnwrap(sut.state.grass)
        let cell = try XCTUnwrap(grass.weeks.joined().first { $0.date == calendar.startOfDay(for: date(2026, 11, 17)) })

        // When
        let cellLabel = ActivityGrass.accessibilityLabel(for: cell, locale: Locale(identifier: "ko_KR"), calendar: calendar)
        let summary = grass.summaryAccessibilityLabel(weekCount: 18)

        // Then
        XCTAssertEqual(cellLabel, "11월 17일 (화), 2번")
        XCTAssertEqual(summary, "최근 18주 중 2일 싶에 다가갔어요")
    }
}
