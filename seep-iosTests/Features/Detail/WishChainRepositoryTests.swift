import XCTest

@testable import seep_ios

/// 싶 잇기 저장소·마이그레이션 (GH-84 R-2, R-6, R-7). 메모리 DB 로 돌린다
final class WishChainRepositoryTests: XCTestCase {
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

    /// 앞 → 뒤 순서로 이어 적는다
    private func addChain(_ ids: [String]) throws {
        var previous: String?
        for id in ids {
            clock = clock.addingTimeInterval(1)
            _ = try sut.addWish(Wish(id: id, title: id, previousWishId: previous, createdAt: clock)).get()
            previous = id
        }
    }

    private func ids(_ chain: WishChain?) -> [String] {
        guard let chain else { return [] }
        return (chain.previous + [chain.current] + chain.next).map(\.id)
    }

    // MARK: GH-84 TC6

    func test_GH84_TC6_ABC체인에서B를지우면_C의체인은A와C다() throws {
        // Given
        try addChain(["A", "B", "C"])

        // When
        sut.deleteWish(id: "B")

        // Then
        let chain = sut.fetchWishChain(wishId: "C")
        XCTAssertEqual(ids(chain), ["A", "C"])
        XCTAssertEqual(chain?.position, 2)
        XCTAssertEqual(ids(sut.fetchWishChain(wishId: "A")), ["A", "C"])
    }

    func test_GH84_TC6_이어진위시가지금하나만남으면_체인이비어있다() throws {
        // Given
        try addChain(["A", "B"])

        // When
        sut.deleteWish(id: "A")

        // Then
        XCTAssertEqual(sut.fetchWishChain(wishId: "B")?.isEmpty, true)
    }

    // MARK: GH-84 TC8

    func test_GH84_TC8_순환참조여도_멈추고두개만보인다() throws {
        // Given: A.previous = B, B.previous = A
        _ = try sut.addWish(Wish(id: "A", title: "A", previousWishId: "B")).get()
        _ = try sut.addWish(Wish(id: "B", title: "B", previousWishId: "A")).get()

        // When
        let chain = sut.fetchWishChain(wishId: "A")

        // Then
        XCTAssertEqual(ids(chain), ["B", "A"])
    }

    // MARK: GH-84 R-7

    func test_GH84_R7_체인이10개를넘으면_앞선싶을접는다() throws {
        // Given: 12개 체인
        let chainIds = (1...12).map { "w\($0)" }
        try addChain(chainIds)

        // When
        let chain = sut.fetchWishChain(wishId: "w12")

        // Then
        XCTAssertEqual(chain?.previous.count, 9)
        XCTAssertEqual(chain?.hiddenPreviousCount, 2)
        XCTAssertEqual(chain?.previous.first?.id, "w3")
        XCTAssertEqual(chain?.position, 12)
    }

    func test_GH84_R3_갈래가있으면_다음싶이모두보인다() throws {
        // Given
        try addChain(["A", "B"])
        clock = clock.addingTimeInterval(1)
        _ = try sut.addWish(Wish(id: "B2", title: "B2", previousWishId: "A", createdAt: clock)).get()

        // When
        let chain = sut.fetchWishChain(wishId: "A")

        // Then
        XCTAssertEqual(chain?.next.map(\.id), ["B", "B2"])
    }

    // MARK: GH-84 TC11

    func test_GH84_TC11_v3스키마의위시는_마이그레이션뒤앞위시없음으로열린다() throws {
        // Given
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v3", seedSQL: [
            "INSERT INTO wish (id, category, title, createdAt, updatedAt) VALUES ('old', 'category_want_to_do', '예전 위시', 100, 0)"
        ])
        let repository = WishRepositoryImpl(database: database)

        // When
        let wish = repository.fetchWish(id: "old")

        // Then
        XCTAssertEqual(wish?.title, "예전 위시")
        XCTAssertNil(wish?.previousWishId)
        XCTAssertEqual(repository.fetchWishChain(wishId: "old")?.isEmpty, true)
    }

    func test_GH84_R2_수정저장해도_앞위시id는그대로다() throws {
        // Given
        try addChain(["A", "B"])
        var wish = try XCTUnwrap(sut.fetchWish(id: "B"))
        wish.title = "고친 B"
        wish.previousWishId = nil

        // When
        _ = try sut.updateWish(wish).get()

        // Then
        XCTAssertEqual(sut.fetchWish(id: "B")?.previousWishId, "A")
    }
}
