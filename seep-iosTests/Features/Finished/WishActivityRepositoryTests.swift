import XCTest

@testable import seep_ios

/// 잔디 집계 저장소 (GH-146 R-2, R-7). 메모리 DB 로 실제 저장소·위젯 저장소를 돌린다
final class WishActivityRepositoryTests: XCTestCase {
    private let suiteName = "test.wishActivityRepository"
    private let calendar = Calendar(identifier: .gregorian)
    private var database: AppDatabase!
    private var clock: Date!
    private var sut: WishRepositoryImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        clock = date(2026, 11, 18, hour: 9)
        sut = WishRepositoryImpl(database: database, now: { [unowned self] in self.clock })
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        database = nil
        sut = nil
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? Date()
    }

    private func allActivities() -> [WishActivity] {
        sut.fetchActivities(from: .distantPast, to: .distantFuture)
    }

    private func activities(on day: Date) -> [WishActivity] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return sut.fetchActivities(from: start, to: end)
    }

    // MARK: TC-1

    func test_GH146_TC1_오늘싶을담고단계를체크하면_오늘칸이2단계이고올해1일이다() throws {
        // Given: 오늘 싶 1개를 담고 단계 1개를 체크했다
        let today = date(2026, 11, 18, hour: 9)
        _ = try sut.addWish(Wish(
            id: "wish-1",
            title: "도쿄 혼자 여행",
            steps: [WishStep(id: "step-1", title: "항공권 알아보기", order: 0)],
            createdAt: today
        )).get()
        clock = today.addingTimeInterval(60 * 60)
        _ = try sut.toggleStep(wishId: "wish-1", stepId: "step-1").get()

        // When: 이룬 싶 탭에 들어간다(실제 저장소를 넣은 화면)
        let viewModel = FinishedViewModel(dependency: .init(
            wishRepository: sut,
            remoteConfigRepository: ActivityStubRemoteConfig(),
            logManager: MockLogManager(),
            now: { today.addingTimeInterval(2 * 60 * 60) },
            calendar: calendar
        ))
        viewModel.send(.onAppear)

        // Then
        let grass = try XCTUnwrap(viewModel.state.grass)
        let todayCell = try XCTUnwrap(grass.weeks.joined().first { $0.date == calendar.startOfDay(for: today) })
        XCTAssertEqual(todayCell.count, 2)
        XCTAssertEqual(todayCell.level, 2)
        XCTAssertEqual(grass.yearDayCount, 1)
    }

    // MARK: TC-2

    func test_GH146_TC2_체크했다가같은날풀면_doneAt이nil이고세지않는다() throws {
        // Given
        _ = try sut.addWish(Wish(
            id: "wish-1",
            title: "위시",
            steps: [WishStep(id: "step-1", title: "단계", order: 0)],
            createdAt: date(2026, 1, 1)
        )).get()
        _ = try sut.toggleStep(wishId: "wish-1", stepId: "step-1").get()
        XCTAssertNotNil(try database.snapshot().steps.first?.doneAt)

        // When: 같은 날 체크를 푼다
        clock = clock.addingTimeInterval(60)
        _ = try sut.toggleStep(wishId: "wish-1", stepId: "step-1").get()

        // Then
        XCTAssertNil(try database.snapshot().steps.first?.doneAt)
        XCTAssertTrue(activities(on: clock).isEmpty)
    }

    // MARK: TC-3

    func test_GH146_TC3_어제이룬싶을오늘완료취소하면_어제칸에서이룸이빠진다() throws {
        // Given: 어제 이룬 싶
        let yesterday = calendar.startOfDay(for: date(2026, 11, 17))
        _ = try sut.addWish(Wish(id: "wish-1", title: "하프 마라톤", finishDate: yesterday, isSuccess: true, createdAt: date(2026, 1, 1))).get()
        XCTAssertEqual(activities(on: yesterday).map(\.kind), [.finished])

        // When: 오늘 완료 취소
        _ = try sut.cancelFinish(wishId: "wish-1").get()

        // Then
        XCTAssertTrue(activities(on: yesterday).isEmpty)
    }

    // MARK: TC-4

    func test_GH146_TC4_삭제표시된위시의모은돈기록은_세지않는다() throws {
        // Given: 모은 돈 기록이 있는 위시를 지웠다
        _ = try sut.addWish(Wish(id: "deleted", category: .wantToGet, title: "피아노", targetAmount: 100_000, createdAt: date(2025, 1, 1))).get()
        _ = try sut.addSaving(wishId: "deleted", amount: 30_000).get()
        _ = try sut.addWish(Wish(id: "alive", category: .wantToGet, title: "카메라", targetAmount: 100_000, createdAt: date(2025, 1, 1))).get()
        _ = try sut.addSaving(wishId: "alive", amount: 10_000).get()
        sut.deleteWish(id: "deleted")

        // When
        let savings = allActivities().filter { if case .saving = $0.kind { return true } else { return false } }

        // Then
        XCTAssertEqual(savings.map(\.wishId), ["alive"])
        XCTAssertFalse(allActivities().contains { $0.wishId == "deleted" })
    }

    // MARK: TC-9

    func test_GH146_TC9_체크위젯에서단계를체크하면_오늘행동으로집계된다() throws {
        // Given
        _ = try sut.addWish(Wish(
            id: "wish-1",
            title: "기타 배우기",
            steps: [WishStep(id: "step-1", title: "코드 외우기", order: 0), WishStep(id: "step-2", title: "한 곡", order: 1)],
            createdAt: date(2026, 1, 1)
        )).get()
        let widgetNow = date(2026, 11, 18, hour: 21)
        let widget = WidgetCheckRepositoryImpl(
            database: database,
            store: WidgetCheckStore(userDefaults: UserDefaults(suiteName: suiteName)),
            now: { widgetNow },
            calendar: calendar
        )

        // When: 위젯에서 단계 체크 + 마지막 단계와 함께 완료
        _ = try widget.checkStep(wishId: "wish-1", stepId: "step-1").get()
        _ = try widget.finishWish(wishId: "wish-1", lastStepId: "step-2").get()

        // Then: 단계 두 건과 이룸이 오늘 칸에 들어간다
        let today = activities(on: widgetNow)
        XCTAssertEqual(today.filter { if case .stepDone = $0.kind { return true } else { return false } }.count, 2)
        XCTAssertTrue(today.contains { $0.kind == .finished })
        XCTAssertEqual(try database.snapshot().steps.compactMap(\.doneAt), [widgetNow, widgetNow])
    }

    // MARK: TC-10

    func test_GH146_TC10_v10DB를마이그레이션하면_doneAt이nil로생기고데이터는그대로다() throws {
        // Given: v10 DB 에 체크된 단계
        let migrated = try AppDatabase.makeInMemory(migratedUpTo: "v10", seedSQL: [
            """
            INSERT INTO wish (id, category, emoji, title, targetAmount, memo, hashtag, isSuccess, createdAt, updatedAt)
            VALUES ('wish-1', 'wantToDo', '🏃', '마라톤', 0, '', '', 0, 700000000, 700000000)
            """,
            """
            INSERT INTO wishStep (id, wishId, title, isDone, "order", updatedAt)
            VALUES ('step-1', 'wish-1', '10km 뛰기', 1, 0, 700000000)
            """
        ])

        // When: 최신(v11)까지 올라갔다

        // Then: 데이터는 그대로이고 doneAt 은 nil
        let step = try XCTUnwrap(try migrated.snapshot().steps.first)
        XCTAssertEqual(step.title, "10km 뛰기")
        XCTAssertTrue(step.isDone)
        XCTAssertNil(step.doneAt)
        XCTAssertEqual(step.updatedAt, Date(timeIntervalSinceReferenceDate: 700_000_000))
        // 지난 체크 날짜는 추정하지 않아 잔디에 없다 (R-7)
        let repository = WishRepositoryImpl(database: migrated)
        XCTAssertFalse(repository.fetchActivities(from: .distantPast, to: .distantFuture).contains {
            if case .stepDone = $0.kind { return true } else { return false }
        })
        // 새 컬럼에 실제로 쓰고 읽힌다(풀었다가 다시 체크)
        _ = try repository.toggleStep(wishId: "wish-1", stepId: "step-1").get()
        _ = try repository.toggleStep(wishId: "wish-1", stepId: "step-1").get()
        XCTAssertNotNil(try migrated.snapshot().steps.first?.doneAt)
    }

    // MARK: TC-15

    func test_GH146_TC15_체크한단계가있는위시를수정폼에서저장해도_doneAt은그대로다() throws {
        // Given
        _ = try sut.addWish(Wish(
            id: "wish-1",
            title: "위시",
            steps: [WishStep(id: "step-1", title: "단계", order: 0)],
            createdAt: date(2026, 1, 1)
        )).get()
        let checkedAt = clock!
        _ = try sut.toggleStep(wishId: "wish-1", stepId: "step-1").get()
        var edited = try XCTUnwrap(sut.fetchWish(id: "wish-1"))

        // When: 하루 뒤 수정 폼에서 제목·단계를 고쳐 저장한다
        clock = clock.addingTimeInterval(24 * 60 * 60)
        edited.title = "고친 위시"
        edited.steps = edited.steps.map { WishStep(id: $0.id, title: "고친 단계", isDone: $0.isDone, order: $0.order) }
            + [WishStep(id: "step-2", title: "새 단계", order: 1)]
        _ = try sut.updateWish(edited).get()

        // Then
        let steps = try database.snapshot().steps.sorted { $0.order < $1.order }
        XCTAssertEqual(steps.map(\.doneAt), [checkedAt, nil])
    }
}

/// 연말 회고 기간이 없는 Remote Config 대역
struct ActivityStubRemoteConfig: RemoteConfigRepository {
    func fetchForceUpdateVersion() async -> Result<String, Error> { .success("") }
    func fetchAndActivate() async {}
    func fetchYearReviewPeriod() -> YearReviewPeriod? { nil }
    func fetchLegacyRealmReimportToken() -> String { "" }
    func fetchSyncEnabled() -> Bool { false }
}
