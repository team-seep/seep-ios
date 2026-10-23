import XCTest

@testable import seep_ios_dev

/// "미래의 나에게" 편지 저장소·마이그레이션 (GH-61 R-1). 메모리 DB·임시 Realm 파일로 돌린다
final class FutureLetterRepositoryTests: XCTestCase {
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

    // MARK: GH-61 TC4

    func test_GH61_TC4_봉인하면_편지와봉인시각이저장되고_다시쓰면덮어쓴다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "wish-1", title: "위시")).get()

        // When
        _ = try sut.sealFutureLetter(wishId: "wish-1", letter: "첫 편지").get()
        clock = clock.addingTimeInterval(86_400)
        let rewritten = try sut.sealFutureLetter(wishId: "wish-1", letter: "새 편지").get()

        // Then
        XCTAssertEqual(rewritten.futureLetter, "새 편지")
        XCTAssertEqual(rewritten.futureLetterSealedAt, clock)
        XCTAssertEqual(sut.fetchWish(id: "wish-1")?.futureLetter, "새 편지")
    }

    // MARK: GH-61 TC11

    func test_GH61_TC11_v1스키마의기존위시는_마이그레이션뒤편지없음으로열린다() throws {
        // Given: v1 스키마에 위시 한 줄
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v1", seedSQL: [
            "INSERT INTO wish (id, category, title, createdAt, updatedAt) VALUES ('old', 'category_want_to_do', '예전 위시', 0, 0)"
        ])

        // When
        let wish = WishRepositoryImpl(database: database).fetchWish(id: "old")

        // Then
        XCTAssertEqual(wish?.title, "예전 위시")
        XCTAssertEqual(wish?.futureLetter, "")
        XCTAssertNil(wish?.futureLetterSealedAt)
        XCTAssertEqual(wish?.hasFutureLetter, false)
    }

    // MARK: GH-61 TC15

    func test_GH61_TC15_Realm데이터에서바로업데이트해도_모든위시가편지없음으로이전된다() throws {
        // Given
        let fixture = try LegacyRealmFixture()
        defer { fixture.remove() }
        try fixture.seed([Wish(id: "realm-wish", title: "Realm 위시")])

        // When
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        let wish = sut.fetchWish(id: "realm-wish")
        XCTAssertEqual(wish?.title, "Realm 위시")
        XCTAssertEqual(wish?.futureLetter, "")
        XCTAssertNil(wish?.futureLetterSealedAt)
    }

    // MARK: GH-61 TC16

    func test_GH61_TC16_편지를쓰거나지우면_위시의updatedAt이갱신된다() throws {
        // Given
        _ = try sut.addWish(Wish(id: "wish-1", title: "위시")).get()

        // When
        clock = clock.addingTimeInterval(60)
        _ = try sut.sealFutureLetter(wishId: "wish-1", letter: "편지").get()
        let afterSeal = try database.snapshot().wishes.first?.updatedAt
        clock = clock.addingTimeInterval(60)
        _ = try sut.deleteFutureLetter(wishId: "wish-1").get()
        let afterDelete = try database.snapshot().wishes.first

        // Then
        XCTAssertEqual(afterSeal, clock.addingTimeInterval(-60))
        XCTAssertEqual(afterDelete?.updatedAt, clock)
        XCTAssertEqual(afterDelete?.futureLetter, "")
        XCTAssertNil(afterDelete?.futureLetterSealedAt)
    }
}
