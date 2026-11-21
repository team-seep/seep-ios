import XCTest

@testable import seep_ios

/// 태그 저장소·마이그레이션 (GH-136 R-1, R-2). 메모리 DB 로 실제 구현을 돌리고 `snapshot()`으로 삭제 표시까지 본다
final class WishTagRepositoryTests: XCTestCase {
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

    @discardableResult
    private func add(_ wish: Wish) throws -> Wish {
        clock = clock.addingTimeInterval(1)
        return try sut.addWish(wish).get()
    }

    // MARK: GH-136 TC1

    func test_GH136_TC1_해시태그하나인기존DB를_마이그레이션하면_태그한줄씩생기고_빈해시태그는없다() throws {
        // Given: v6 스키마에 기본 태그·직접 입력·빈 값·지운 위시
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v6", seedSQL: [
            "INSERT INTO wish (id, category, title, hashtag, createdAt, updatedAt) VALUES ('A', 'category_want_to_do', 'A', 'trip', 100, 10)",
            "INSERT INTO wish (id, category, title, hashtag, createdAt, updatedAt) VALUES ('B', 'category_want_to_do', 'B', '독서', 200, 20)",
            "INSERT INTO wish (id, category, title, hashtag, createdAt, updatedAt) VALUES ('C', 'category_want_to_do', 'C', '  ', 300, 30)",
            "INSERT INTO wish (id, category, title, hashtag, createdAt, updatedAt, deletedAt) VALUES ('D', 'category_want_to_do', 'D', 'life', 400, 40, 50)"
        ])
        let repository = WishRepositoryImpl(database: database)

        // When
        let tags = try database.snapshot().tags

        // Then
        XCTAssertEqual(repository.fetchWish(id: "A")?.tags, ["trip"])
        XCTAssertEqual(repository.fetchWish(id: "B")?.tags, ["독서"])
        XCTAssertEqual(repository.fetchWish(id: "C")?.tags, [])
        XCTAssertEqual(tags.map(\.wishId).sorted(), ["A", "B", "D"])
        XCTAssertEqual(Set(tags.map(\.id)).count, 3)
        XCTAssertEqual(tags.first { $0.wishId == "D" }?.deletedAt, Date(timeIntervalSinceReferenceDate: 50))
        XCTAssertEqual(tags.first { $0.wishId == "A" }?.updatedAt, Date(timeIntervalSinceReferenceDate: 10))
    }

    // MARK: GH-136 TC2

    func test_GH136_TC2_태그3개로저장하면_순서대로읽히고_대표태그컬럼은첫태그다() throws {
        // When
        try add(Wish(id: "w", title: "제주", tags: ["trip", "life", "독서"]))

        // Then
        XCTAssertEqual(sut.fetchWish(id: "w")?.tags, ["trip", "life", "독서"])
        XCTAssertEqual(try database.snapshot().wishes.first?.hashtag, "trip")
    }

    // MARK: GH-136 TC5

    func test_GH136_TC5_수정에서하나를빼면_빠진태그만삭제표시되고_남은태그는id가그대로다() throws {
        // Given
        let wish = try add(Wish(id: "w", title: "제주", tags: ["trip", "life", "독서"]))
        let before = try database.snapshot().tags
        clock = clock.addingTimeInterval(60)
        var edited = wish
        edited.tags = ["trip", "독서"]

        // When
        let saved = try sut.updateWish(edited).get()

        // Then
        XCTAssertEqual(saved.tags, ["trip", "독서"])
        let after = try database.snapshot().tags
        XCTAssertEqual(after.count, 3)
        let removed = try XCTUnwrap(after.first { $0.name == "life" })
        XCTAssertEqual(removed.deletedAt, clock)
        let kept = after.filter { $0.deletedAt == nil }
        XCTAssertEqual(Set(kept.map(\.id)), Set(before.filter { $0.name != "life" }.map(\.id)))
        XCTAssertEqual(kept.first { $0.name == "독서" }?.order, 1)
        XCTAssertEqual(try database.snapshot().wishes.first?.hashtag, "trip")
    }

    func test_GH136_TC5_위시를지우면_태그도삭제표시된다() throws {
        // Given
        try add(Wish(id: "w", title: "제주", tags: ["trip", "독서"]))
        clock = clock.addingTimeInterval(60)

        // When
        sut.deleteWish(id: "w")

        // Then
        XCTAssertEqual(try database.snapshot().tags.map(\.deletedAt), [clock, clock])
    }

    // MARK: GH-136 TC16

    func test_GH136_TC16_전에쓴태그는_기본태그와지운위시를빼고_최근것부터한번씩이다() throws {
        // Given
        try add(Wish(id: "old", title: "오래된", tags: ["trip", "요리"]))
        try add(Wish(id: "mid", title: "중간", tags: ["요리"]))
        try add(Wish(id: "new", title: "최근", tags: ["독서"]))
        try add(Wish(id: "gone", title: "지움", tags: ["사라질"]))
        sut.deleteWish(id: "gone")

        // When
        let tags = sut.fetchRecentCustomTags()

        // Then
        XCTAssertEqual(tags, ["독서", "요리"])
    }
}
