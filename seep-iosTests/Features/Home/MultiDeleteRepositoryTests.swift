import XCTest

@testable import seep_ios_dev

/// 일괄 삭제 저장소 (GH-86 R-4). 메모리 DB 로 돌린다
final class MultiDeleteRepositoryTests: XCTestCase {
    func test_GH86_TC4_여러위시를한번에삭제표시한다() throws {
        // Given
        let sut = WishRepositoryImpl(database: try AppDatabase.makeInMemory())
        for id in ["a", "b", "c"] { _ = try sut.addWish(Wish(id: id, title: id)).get() }

        // When
        _ = try sut.deleteWishes(ids: ["a", "b"]).get()

        // Then
        XCTAssertNil(sut.fetchWish(id: "a"))
        XCTAssertNil(sut.fetchWish(id: "b"))
        XCTAssertNotNil(sut.fetchWish(id: "c"))
    }

    func test_GH86_TC6_하나라도실패하면_아무것도지우지않는다() throws {
        // Given
        let sut = WishRepositoryImpl(database: try AppDatabase.makeInMemory())
        _ = try sut.addWish(Wish(id: "a", title: "a")).get()

        // When: 없는 id 가 섞여 있다
        let result = sut.deleteWishes(ids: ["a", "missing"])

        // Then
        guard case .failure = result else { return XCTFail("실패해야 한다") }
        XCTAssertNotNil(sut.fetchWish(id: "a"))
    }
}
