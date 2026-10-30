import XCTest

@testable import seep_ios

/// "내가 정한 순서" 저장소·마이그레이션 (GH-73 R-3, R-7, R-8). 메모리 DB·임시 Realm 파일로 돌린다
final class ManualOrderRepositoryTests: XCTestCase {
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

    private func manualIds(_ category: seep_ios.Category = .wantToDo) -> [String] {
        sut.fetchWishes(category: category, sort: .manualOrder, isOnlyFinished: false).map(\.id)
    }

    /// 만든 순서대로 넣는다. 새 위시는 맨 위로 가므로 마지막에 넣은 것이 맨 위다
    private func add(_ ids: [String], category: seep_ios.Category = .wantToDo) throws {
        for id in ids {
            clock = clock.addingTimeInterval(1)
            _ = try sut.addWish(Wish(id: id, category: category, title: id, createdAt: clock)).get()
        }
    }

    private func move(_ id: String, to ordered: [String]) throws {
        _ = try sut.moveWish(wishId: id, orderedIds: ordered).get()
    }

    // MARK: GH-73 TC3

    func test_GH73_TC3_v1스키마의위시는_마이그레이션뒤카테고리마다최근생성순이다() throws {
        // Given: v1(또는 v2) 스키마에 오래된 A, 최근 B, 다른 카테고리 G
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v2", seedSQL: [
            "INSERT INTO wish (id, category, title, createdAt, updatedAt) VALUES ('A', 'category_want_to_do', 'A', 100, 0)",
            "INSERT INTO wish (id, category, title, createdAt, updatedAt) VALUES ('B', 'category_want_to_do', 'B', 200, 0)",
            "INSERT INTO wish (id, category, title, createdAt, updatedAt) VALUES ('G', 'category_want_to_get', 'G', 150, 0)"
        ])
        let repository = WishRepositoryImpl(database: database)

        // When
        let wishes = repository.fetchWishes(category: .wantToDo, sort: .manualOrder, isOnlyFinished: false)

        // Then
        XCTAssertEqual(wishes.map(\.id), ["B", "A"])
        XCTAssertEqual(wishes.map(\.manualOrder), [1, 2])
        XCTAssertEqual(repository.fetchWish(id: "G")?.manualOrder, 1)
    }

    // MARK: GH-73 TC4

    func test_GH73_TC4_C를A와B사이로옮기면_ACB순서로저장되고_C한건만갱신된다() throws {
        // Given: C 다음 B 다음 A 로 넣어 화면 순서가 A, B, C 가 되게 한다
        try add(["C", "B", "A"])
        XCTAssertEqual(manualIds(), ["A", "B", "C"])
        let before = try database.snapshot().wishes
        clock = clock.addingTimeInterval(60)

        // When
        try move("C", to: ["A", "C", "B"])

        // Then
        XCTAssertEqual(manualIds(), ["A", "C", "B"])
        let after = try database.snapshot().wishes
        let changed = after.filter { record in before.first { $0.id == record.id } != record }.map(\.id)
        XCTAssertEqual(changed, ["C"])
    }

    func test_GH73_TC4_간격이너무좁아지면_목록을다시매긴다() throws {
        // Given
        try add(["C", "B", "A"])

        // When: A와 B 사이로 60번 넘게 번갈아 옮겨 간격을 좁힌다
        var order = ["A", "B", "C"]
        for _ in 0..<60 {
            order = order[0] == "A" ? ["A", "C", "B"] : ["A", "B", "C"]
            let moved = order[1]
            try move(moved, to: order)
        }

        // Then
        XCTAssertEqual(manualIds(), order)
    }

    // MARK: GH-73 TC5

    func test_GH73_TC5_고정위시P아래로B를옮겨도_P가맨위에있다() throws {
        // Given
        try add(["A", "B", "P"])
        _ = try sut.updatePin(wishId: "P", isPinned: true).get()

        // When: 옮길 목록(고정 제외) 맨 위로 A
        try move("A", to: ["A", "B"])

        // Then
        XCTAssertEqual(manualIds(), ["P", "A", "B"])
    }

    // MARK: GH-73 TC6

    func test_GH73_TC6_새위시는_고정위시바로아래맨위에있다() throws {
        // Given
        try add(["A", "P"])
        _ = try sut.updatePin(wishId: "P", isPinned: true).get()

        // When
        try add(["N"])

        // Then
        XCTAssertEqual(manualIds(), ["P", "N", "A"])
    }

    // MARK: GH-73 TC12

    func test_GH73_TC12_카테고리를바꾸면_새카테고리의맨위로간다() throws {
        // Given
        try add(["D1", "D2"], category: .wantToDo)
        try add(["X"], category: .wantToGet)
        var wish = try XCTUnwrap(sut.fetchWish(id: "X"))
        wish.category = .wantToDo

        // When
        _ = try sut.updateWish(wish).get()

        // Then
        XCTAssertEqual(manualIds(.wantToDo).first, "X")
    }

    func test_GH73_R8_완료를취소하면_원래순서로돌아간다() throws {
        // Given
        try add(["C", "B", "A"])
        let wish = try XCTUnwrap(sut.fetchWish(id: "B"))
        _ = try sut.finishWish(wish: wish).get()

        // When
        _ = try sut.cancelFinish(wishId: "B").get()

        // Then
        XCTAssertEqual(manualIds(), ["A", "B", "C"])
    }

    // MARK: GH-73 TC13

    func test_GH73_TC13_Realm데이터에서바로업데이트해도_최근생성순이다() throws {
        // Given
        let fixture = try LegacyRealmFixture()
        defer { fixture.remove() }
        try fixture.seed([
            Wish(id: "old", title: "오래됨", createdAt: Date(timeIntervalSinceReferenceDate: 100)),
            Wish(id: "new", title: "최근", createdAt: Date(timeIntervalSinceReferenceDate: 200))
        ])

        // When
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        XCTAssertEqual(manualIds(), ["new", "old"])
    }

    // MARK: GH-73 TC14

    func test_GH73_TC14_옮기면_옮긴위시의updatedAt만갱신된다() throws {
        // Given
        try add(["C", "B", "A"])
        clock = clock.addingTimeInterval(60)

        // When
        try move("A", to: ["B", "A", "C"])

        // Then
        let records = try database.snapshot().wishes
        XCTAssertEqual(records.filter { $0.updatedAt == clock }.map(\.id), ["A"])
    }
}
