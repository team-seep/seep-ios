import XCTest

@testable import seep_ios_dev

/// 체크 위젯 저장소 (GH-48 R-3, R-4, R-6, R-7). 메모리 DB(GH-79)와 테스트용 UserDefaults 로 돌린다.
final class WidgetCheckRepositoryTests: XCTestCase {
    private let suiteName = "test.widgetCheckRepository"
    private var database: AppDatabase!
    private var store: WidgetCheckStore!
    private var sut: WidgetCheckRepositoryImpl!
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        UserDefaults().removePersistentDomain(forName: suiteName)
        store = WidgetCheckStore(userDefaults: UserDefaults(suiteName: suiteName))
        sut = WidgetCheckRepositoryImpl(database: database, store: store, now: { [now] in now })
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        database = nil
        super.tearDown()
    }

    private func save(_ wish: Wish) throws {
        _ = try WishRepositoryImpl(database: database).addWish(wish).get()
    }

    // MARK: GH-48 TC6

    func test_GH48_TC6_미완료위시를위젯에서완료하면_완료날짜가생기고고정이풀리고목록에id가쌓인다() throws {
        // Given
        let wish = Wish(id: "wish-1", title: "기타로 노래 한 곡 치기", pinnedAt: now.addingTimeInterval(-60))
        try save(wish)

        // When
        let result = sut.finishWish(wishId: wish.id, lastStepId: nil)

        // Then
        guard case .success(let finished) = result else { return XCTFail("완료에 실패했다") }
        XCTAssertTrue(finished.isSuccess)
        XCTAssertEqual(finished.finishDate, Calendar.current.startOfDay(for: now))
        XCTAssertNil(finished.pinnedAt)
        XCTAssertEqual(store.finishedWishIds, ["wish-1"])
        XCTAssertEqual(store.doneWishIds(now: now), ["wish-1"])
        XCTAssertEqual(store.actionLogs, [.init(action: .finishWish, at: now)])
    }

    func test_GH48_TC6_마지막단계가남은위시를완료하면_그단계도완료된다() throws {
        // Given
        let steps = [
            WishStep(id: "step-1", title: "첫 단계", isDone: true, order: 0),
            WishStep(id: "step-2", title: "마지막 단계", order: 1)
        ]
        try save(Wish(id: "wish-1", title: "위시", steps: steps))

        // When
        let result = sut.finishWish(wishId: "wish-1", lastStepId: "step-2")

        // Then
        guard case .success(let finished) = result else { return XCTFail("완료에 실패했다") }
        XCTAssertTrue(finished.isSuccess)
        XCTAssertEqual(finished.steps.map(\.isDone), [true, true])
    }

    func test_GH48_TC6_가장최근에완료한위시가목록맨앞에온다() throws {
        // Given
        try save(Wish(id: "wish-1", title: "첫 번째"))
        try save(Wish(id: "wish-2", title: "두 번째"))

        // When
        _ = sut.finishWish(wishId: "wish-1", lastStepId: nil)
        _ = sut.finishWish(wishId: "wish-2", lastStepId: nil)

        // Then
        XCTAssertEqual(store.finishedWishIds, ["wish-2", "wish-1"])
    }

    // MARK: GH-48 TC7

    func test_GH48_TC7_위젯에서완료한위시를취소하면_완료가풀리고목록에서빠진다() throws {
        // Given
        try save(Wish(id: "wish-1", title: "기타로 노래 한 곡 치기"))
        _ = sut.finishWish(wishId: "wish-1", lastStepId: nil)

        // When
        let result = sut.unfinishWish(wishId: "wish-1")

        // Then
        guard case .success(let unfinished) = result else { return XCTFail("완료 취소에 실패했다") }
        XCTAssertFalse(unfinished.isSuccess)
        XCTAssertNil(unfinished.finishDate)
        XCTAssertEqual(store.finishedWishIds, [])
        XCTAssertEqual(store.doneWishIds(now: now), [])
        XCTAssertEqual(store.actionLogs.map(\.action), [.finishWish, .unfinishWish])
    }

    // MARK: GH-48 R-1, R-4 (TC10~12 자동화의 목록 기준)

    func test_GH48_TC11_오늘위젯에서완료한위시는목록에남고_다른완료위시는빠진다() throws {
        // Given
        try save(Wish(id: "open", title: "미완료"))
        try save(Wish(id: "done-in-app", title: "앱에서 완료", isSuccess: true))
        try save(Wish(id: "done-in-widget", title: "위젯에서 완료"))
        _ = sut.finishWish(wishId: "done-in-widget", lastStepId: nil)

        // When
        let wishes = sut.fetchCheckWidgetWishes(limit: 3)

        // Then
        XCTAssertEqual(Set(wishes.map(\.id)), ["open", "done-in-widget"])
    }

    func test_GH48_TC11_다음날이되면위젯에서완료한줄이목록에서빠진다() throws {
        // Given
        try save(Wish(id: "done-in-widget", title: "위젯에서 완료"))
        _ = sut.finishWish(wishId: "done-in-widget", lastStepId: nil)
        let tomorrow = now.addingTimeInterval(60 * 60 * 24)
        let tomorrowRepository = WidgetCheckRepositoryImpl(
            database: database,
            store: store,
            now: { tomorrow }
        )

        // When
        let wishes = tomorrowRepository.fetchCheckWidgetWishes(limit: 3)

        // Then
        XCTAssertTrue(wishes.isEmpty)
    }

    // MARK: 회귀 (GH-48 R-7, R-13 의 알림 취소 전제)

    func test_회귀_저장된위시를다시읽어도_예약때쓴알림id가유지된다() throws {
        // Given
        let notification = SeepNotification(type: .dayAgo)
        try save(Wish(id: "wish-1", title: "위시", endDate: now, notifications: [notification]))

        // When
        let wish = sut.fetchWish(id: "wish-1")

        // Then
        XCTAssertEqual(wish?.notifications.map(\.id), [notification.id])
    }
}
