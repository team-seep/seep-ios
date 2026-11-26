import XCTest

@testable import seep_ios

/// '시작했어요' 저장소·마이그레이션 (GH-143 R-1, R-6, R-7). 메모리 DB 로 실제 구현을 돌린다
final class WishStartRepositoryTests: XCTestCase {
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

    private func tick(_ seconds: TimeInterval = 60) {
        clock = clock.addingTimeInterval(seconds)
    }

    // MARK: GH-143 TC1

    func test_GH143_TC1_v10까지돈DB를v11로올리면_모든싶이시작전이고_다른컬럼은그대로다() throws {
        // Given: v10 스키마의 진행 중·이룬·지운 위시
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v10", seedSQL: [
            "INSERT INTO wish (id, category, title, memo, isSuccess, createdAt, updatedAt) VALUES ('A', 'category_want_to_do', '서핑', '양양', 0, 100, 10)",
            "INSERT INTO wish (id, category, title, isSuccess, finishDate, createdAt, updatedAt) VALUES ('B', 'category_want_to_go', '제주', 1, 300, 200, 20)",
            "INSERT INTO wish (id, category, title, createdAt, updatedAt, deletedAt) VALUES ('C', 'category_want_to_get', '에어팟', 300, 30, 40)"
        ])

        // When: 앱 업데이트 — 남은 마이그레이션(v11)이 돈 뒤 읽는다
        let wishes = try database.snapshot().wishes.sorted { $0.id < $1.id }

        // Then
        XCTAssertEqual(wishes.map(\.startedAt), [nil, nil, nil])
        XCTAssertEqual(wishes.map(\.title), ["서핑", "제주", "에어팟"])
        XCTAssertEqual(wishes.map(\.memo), ["양양", "", ""])
        XCTAssertEqual(wishes.map(\.isSuccess), [false, true, false])
        XCTAssertEqual(wishes.map(\.finishDate), [nil, Date(timeIntervalSinceReferenceDate: 300), nil])
        XCTAssertEqual(wishes.map(\.updatedAt), [10, 20, 30].map(Date.init(timeIntervalSinceReferenceDate:)))
        XCTAssertEqual(wishes.map(\.deletedAt), [nil, nil, Date(timeIntervalSinceReferenceDate: 40)])
    }

    // MARK: GH-143 TC2

    func test_GH143_TC2_시작하면지금시각이저장되고_되돌리면nil이며_매번updatedAt이갱신된다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "w", title: "서핑")).get()
        tick()

        // When
        let started = try sut.updateStarted(wishId: "w", isStarted: true).get()

        // Then
        XCTAssertEqual(started.startedAt, clock)
        XCTAssertEqual(try database.snapshot().wishes.first?.updatedAt, clock)

        // When
        tick()
        let stopped = try sut.updateStarted(wishId: "w", isStarted: false).get()

        // Then
        XCTAssertNil(stopped.startedAt)
        XCTAssertNil(sut.fetchWish(id: "w")?.startedAt)
        XCTAssertEqual(try database.snapshot().wishes.first?.updatedAt, clock)
    }

    func test_GH143_TC2_이미시작한싶에다시시작을저장해도_처음시작한시각을지킨다() throws {
        // Given: 다른 기기에서 먼저 시작해 받아 왔다
        _ = try sut.addWish(Wish(id: "w", title: "서핑")).get()
        let first = try XCTUnwrap(sut.updateStarted(wishId: "w", isStarted: true).get().startedAt)
        tick(86_400 * 4)

        // When: 오래된 화면 값으로 다시 시작이 불렸다
        let again = try sut.updateStarted(wishId: "w", isStarted: true).get()

        // Then
        XCTAssertEqual(again.startedAt, first)
    }

    // MARK: GH-143 TC10

    func test_GH143_TC10_하는중싶을이뤄도시작시각이남고_완료를취소하면다시하는중이다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "w", title: "서핑")).get()
        let startedAt = try XCTUnwrap(sut.updateStarted(wishId: "w", isStarted: true).get().startedAt)
        tick(86_400 * 11)
        let wish = try XCTUnwrap(sut.fetchWish(id: "w"))

        // When
        _ = try sut.finishWish(wish: wish).get()

        // Then
        let finished = try XCTUnwrap(sut.fetchWish(id: "w"))
        XCTAssertTrue(finished.isSuccess)
        XCTAssertEqual(finished.startedAt, startedAt)
        XCTAssertFalse(finished.isInProgress)

        // When
        let restored = try sut.cancelFinish(wishId: "w").get()

        // Then
        XCTAssertEqual(restored.startedAt, startedAt)
        XCTAssertTrue(restored.isInProgress)
    }

    // MARK: GH-143 TC11

    func test_GH143_TC11_하는중싶을수정화면에서카테고리를바꿔저장해도_시작시각이그대로다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "w", category: .wantToDo, title: "서핑")).get()
        let startedAt = try XCTUnwrap(sut.updateStarted(wishId: "w", isStarted: true).get().startedAt)
        tick()
        var edited = try XCTUnwrap(sut.fetchWish(id: "w"))
        edited.category = .wantToGo
        // 수정 폼이 시작 상태를 모르고 넘겨도 지우지 않는다
        edited.startedAt = nil

        // When
        let saved = try sut.updateWish(edited).get()

        // Then
        XCTAssertEqual(saved.category, .wantToGo)
        XCTAssertEqual(saved.startedAt, startedAt)
    }

    func test_GH143_TC11_이어서적은새싶은_앞싶이하는중이어도시작전이다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "prev", title: "올레길 1코스")).get()
        _ = try sut.updateStarted(wishId: "prev", isStarted: true).get()

        // When
        let next = try sut.addWish(Wish(id: "next", title: "올레길 2코스", previousWishId: "prev")).get()

        // Then
        XCTAssertNil(next.startedAt)
        XCTAssertNotNil(sut.fetchWish(id: "prev")?.startedAt)
    }
}
