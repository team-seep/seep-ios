import XCTest

@testable import seep_ios

/// 기한 종류 저장소·마이그레이션·정렬 (GH-118 R-1, R-2, R-6, R-7). 메모리 DB 로 실제 구현을 돌린다
final class DeadlineKindRepositoryTests: XCTestCase {
    private var database: AppDatabase!
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private var sut: WishRepositoryImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeInMemory()
        sut = WishRepositoryImpl(database: database, now: { [unowned self] in self.clock })
    }

    override func tearDown() {
        database = nil
        sut = nil
        super.tearDown()
    }

    /// 그날 23:59:59 (기기 시간대) — 기간 기한이 저장하는 마감
    private func end(_ year: Int, _ month: Int, _ day: Int) -> Date {
        (Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()).endOfDay
    }

    // MARK: GH-118 TC8

    func test_GH118_TC8_v12까지돈DB를올리면_기존위시는날짜기한이고_마감과정렬이그대로다() throws {
        // Given: v12 스키마의 날짜 기한·일정없음 위시
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v12", seedSQL: [
            "INSERT INTO wish (id, category, title, date, createdAt, updatedAt) VALUES ('A', 'category_want_to_do', '서핑', 5000, 100, 10)",
            "INSERT INTO wish (id, category, title, date, createdAt, updatedAt) VALUES ('B', 'category_want_to_do', '제주', 3000, 200, 20)",
            "INSERT INTO wish (id, category, title, createdAt, updatedAt) VALUES ('C', 'category_want_to_do', '오로라', 300, 30)"
        ])

        // When: 앱 업데이트 — 남은 마이그레이션(v14)이 돈 뒤 읽는다
        try database.migrateToLatest()
        let records = try database.snapshot().wishes.sorted { $0.id < $1.id }
        let wishes = WishRepositoryImpl(database: database).fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false)

        // Then
        XCTAssertEqual(records.map(\.deadlineKind), ["", "", ""])
        XCTAssertEqual(records.map(\.updatedAt), [10, 20, 30].map(Date.init(timeIntervalSinceReferenceDate:)), "마이그레이션이 updatedAt 을 건드리지 않아 다시 올리지 않는다")
        XCTAssertEqual(wishes.map(\.id), ["B", "A", "C"])
        XCTAssertEqual(wishes.map(\.deadlineKind), [.date, .date, .date])
        XCTAssertEqual(wishes.map(\.endDate), [3000, 5000].map(Date.init(timeIntervalSinceReferenceDate:)) + [nil])
    }

    func test_GH118_TC8_date나모르는값으로저장된종류는_날짜기한으로읽는다() {
        XCTAssertEqual(DeadlineKind(stored: "date"), .date)
        XCTAssertEqual(DeadlineKind(stored: ""), .date)
        XCTAssertEqual(DeadlineKind(stored: "decade"), .date)
        XCTAssertEqual(DeadlineKind(stored: "next_year"), .nextYear)
    }

    // MARK: GH-118 TC9

    func test_GH118_TC9_완료일가까운순은_기간마지막날기준으로날짜기한과섞여정렬된다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "year", title: "올해 안", endDate: end(2026, 12, 31), deadlineKind: .year)).get()
        _ = try sut.addWish(Wish(id: "date-near", title: "날짜 가까움", endDate: end(2026, 11, 20))).get()
        _ = try sut.addWish(Wish(id: "month", title: "이번 달", endDate: end(2026, 11, 30), deadlineKind: .month)).get()
        _ = try sut.addWish(Wish(id: "none", title: "일정없음")).get()
        _ = try sut.addWish(Wish(id: "date-far", title: "날짜 멀리", endDate: end(2026, 12, 15))).get()

        // When
        let wishes = sut.fetchWishes(category: .wantToDo, sort: .deadlineOrder, isOnlyFinished: false)

        // Then
        XCTAssertEqual(wishes.map(\.id), ["date-near", "month", "date-far", "year", "none"])
        XCTAssertEqual(wishes.map(\.deadlineKind), [.date, .month, .date, .year, .date])
    }

    // MARK: GH-118 TC6 · TC7 (저장소)

    func test_GH118_TC6_기한을미루면_마감과종류가바뀌고_알림은남으며_updatedAt이갱신된다() throws {
        // Given
        let notification = SeepNotification(id: "n1", type: .dayAgo, time: Date(timeIntervalSinceReferenceDate: 0))
        _ = try sut.addWish(Wish(id: "w", title: "서핑", endDate: end(2026, 12, 31), deadlineKind: .year, notifications: [notification])).get()
        clock = clock.addingTimeInterval(60)
        let newEnd = end(2027, 12, 31)

        // When
        let saved = try sut.updateDeadline(wishId: "w", endDate: newEnd, kind: .year).get()

        // Then
        XCTAssertEqual(saved.endDate, newEnd)
        XCTAssertEqual(saved.deadlineKind, .year)
        XCTAssertEqual(saved.notifications.map(\.id), ["n1"])
        XCTAssertEqual(try database.snapshot().wishes.first?.updatedAt, clock)
    }

    func test_GH118_TC7_기한을없애면_날짜기한빈값이고_알림줄은삭제표시된다() throws {
        // Given
        let notification = SeepNotification(id: "n1", type: .dayAgo, time: Date(timeIntervalSinceReferenceDate: 0))
        _ = try sut.addWish(Wish(id: "w", title: "서핑", endDate: end(2026, 10, 31), deadlineKind: .month, notifications: [notification])).get()

        // When
        let saved = try sut.updateDeadline(wishId: "w", endDate: nil, kind: .month).get()

        // Then
        XCTAssertNil(saved.endDate)
        XCTAssertEqual(saved.deadlineKind, .date)
        XCTAssertEqual(saved.notifications, [])
        let snapshot = try database.snapshot()
        XCTAssertEqual(snapshot.wishes.first?.deadlineKind, "")
        XCTAssertEqual(snapshot.notifications.map(\.id), ["n1"])
        XCTAssertNotNil(snapshot.notifications.first?.deletedAt, "삭제는 표시만 한다 (R4)")
    }

    func test_GH118_TC1_수정폼으로저장해도_기한종류가저장된다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "w", title: "서핑")).get()
        let saved = end(2027, 12, 31)

        // When
        _ = try sut.updateWish(Wish(id: "w", title: "서핑", endDate: saved, deadlineKind: .nextYear)).get()

        // Then
        XCTAssertEqual(sut.fetchWish(id: "w")?.deadlineKind, .nextYear)
        XCTAssertEqual(sut.fetchWish(id: "w")?.endDate, saved)
    }

    // MARK: GH-118 TC18

    func test_GH118_TC18_기간종류인데마감이기간마지막날이아니면_날짜기한으로읽는다() throws {
        // Given: 구버전 앱이 "올해 안" 위시의 날짜만 3월 5일로 바꿔 동기화한 상태 (deadlineKind 는 서버에 남았다)
        _ = try sut.addWish(Wish(id: "old-app", title: "서핑", endDate: end(2027, 3, 5), deadlineKind: .year)).get()
        _ = try sut.addWish(Wish(id: "month-ok", title: "책", endDate: end(2027, 2, 28), deadlineKind: .month)).get()
        _ = try sut.addWish(Wish(id: "month-bad", title: "요가", endDate: end(2027, 2, 27), deadlineKind: .month)).get()

        // When
        let oldApp = sut.fetchWish(id: "old-app")

        // Then
        XCTAssertEqual(oldApp?.deadlineKind, .date)
        XCTAssertEqual(oldApp?.endDate, end(2027, 3, 5))
        XCTAssertEqual(sut.fetchWish(id: "month-ok")?.deadlineKind, .month)
        XCTAssertEqual(sut.fetchWish(id: "month-bad")?.deadlineKind, .date)
        XCTAssertEqual(DdayBadgeStyle(wish: try XCTUnwrap(oldApp), today: end(2027, 1, 1)).text(farFuture: "", noDate: ""), "D-63")
    }
}
