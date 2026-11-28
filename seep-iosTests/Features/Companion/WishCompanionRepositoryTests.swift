import XCTest

@testable import seep_ios

/// 함께할 사람 저장소 (GH-122 R-3, R-8, R-11, R-12). 메모리 DB 로 실제 구현을 돌리고 `snapshot()`으로 삭제 표시까지 본다
final class WishCompanionRepositoryTests: XCTestCase {
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

    @discardableResult
    private func update(_ wish: Wish) throws -> Wish {
        clock = clock.addingTimeInterval(1)
        return try sut.updateWish(wish).get()
    }

    // MARK: TC-1

    func test_GH122_TC1_엄마와지은을붙여저장하면_고른순서대로읽힌다() throws {
        // When
        try add(Wish(id: "w", title: "제주", companions: [WishCompanion(name: "엄마"), WishCompanion(name: "지은")]))

        // Then
        XCTAssertEqual(sut.fetchWish(id: "w")?.companions.map(\.name), ["엄마", "지은"])
    }

    // MARK: TC-2

    func test_GH122_TC2_공백있는이름은다듬고_같은이름은한번만저장된다() throws {
        // When: 화면을 거치지 않고 들어와도 저장소가 정리한다
        try add(Wish(id: "w", title: "제주", companions: [WishCompanion(name: "  엄마 "), WishCompanion(name: "엄마"), WishCompanion(name: "   ")]))

        // Then
        XCTAssertEqual(sut.fetchWish(id: "w")?.companions.map(\.name), ["엄마"])
        XCTAssertEqual(try database.snapshot().companions.count, 1)
    }

    // MARK: TC-5

    func test_GH122_TC5_삭제된위시에서만쓴사람은_전에적은사람에없다() throws {
        // Given
        try add(Wish(id: "a", title: "효도 여행", companions: [WishCompanion(name: "엄마")]))
        try add(Wish(id: "b", title: "캠핑", companions: [WishCompanion(name: "지은")]))

        // When
        clock = clock.addingTimeInterval(1)
        sut.deleteWish(id: "a")

        // Then
        XCTAssertEqual(sut.fetchRecentCompanions().map(\.name), ["지은"])
    }

    func test_GH122_TC5_전에적은사람은_최근에쓴사람부터_한번씩나온다() throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        try add(Wish(id: "a", title: "효도 여행", companions: [mom]))
        try add(Wish(id: "b", title: "캠핑", companions: [WishCompanion(name: "지은")]))
        try add(Wish(id: "c", title: "김치찌개", companions: [mom]))

        // Then
        XCTAssertEqual(sut.fetchRecentCompanions().map(\.name), ["엄마", "지은"])
    }

    // MARK: TC-6

    func test_GH122_TC6_그사람이붙은살아있는위시만_세카테고리에서모인다() throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        try add(Wish(id: "do", category: .wantToDo, title: "제주", companions: [mom]))
        try add(Wish(id: "get", category: .wantToGet, title: "카메라", companions: [mom, WishCompanion(name: "지은")]))
        try add(Wish(id: "go", category: .wantToGo, title: "진해", companions: [mom]))
        try add(Wish(id: "other", title: "캠핑", companions: [WishCompanion(name: "지은")]))
        try add(Wish(id: "gone", title: "지운 것", companions: [mom]))
        sut.deleteWish(id: "gone")

        // When
        let wishes = sut.fetchCompanionWishes(personId: mom.personId)

        // Then
        XCTAssertEqual(Set(wishes.map(\.id)), ["do", "get", "go"])
    }

    // MARK: TC-8

    func test_GH122_TC8_사람하나를빼고저장하면_그줄은삭제표시되고조회에서빠진다() throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        let jieun = WishCompanion(name: "지은")
        var wish = try add(Wish(id: "w", title: "제주", companions: [mom, jieun]))

        // When
        wish.companions = [jieun]
        try update(wish)

        // Then
        XCTAssertEqual(sut.fetchWish(id: "w")?.companions.map(\.name), ["지은"])
        let rows = try database.snapshot().companions
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows.first { $0.personId == mom.personId }?.deletedAt, clock)
        XCTAssertNil(rows.first { $0.personId == jieun.personId }?.deletedAt)
    }

    func test_GH122_TC8_남은사람은_줄id를그대로두고순서만고친다() throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        let jieun = WishCompanion(name: "지은")
        var wish = try add(Wish(id: "w", title: "제주", companions: [mom, jieun]))
        let idsBefore = Set(try database.snapshot().companions.map(\.id))

        // When
        wish.companions = [jieun, mom]
        try update(wish)

        // Then: 새 줄 없이 순서만 바뀐다 (동기화 때 같은 사람이 새 줄로 바뀌지 않게)
        XCTAssertEqual(sut.fetchWish(id: "w")?.companions.map(\.name), ["지은", "엄마"])
        XCTAssertEqual(Set(try database.snapshot().companions.map(\.id)), idsBefore)
    }

    // MARK: TC-9

    func test_GH122_TC9_위시를지우면_붙은사람줄도모두삭제표시된다() throws {
        // Given
        try add(Wish(id: "w", title: "제주", companions: [WishCompanion(name: "엄마"), WishCompanion(name: "지은")]))

        // When
        clock = clock.addingTimeInterval(1)
        sut.deleteWish(id: "w")

        // Then
        let rows = try database.snapshot().companions
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows.allSatisfy { $0.deletedAt == clock })
    }

    // MARK: TC-14

    func test_GH122_TC14_전에적은사람칩이나같은이름을직접적으면_같은personId로모인다() throws {
        // Given
        try add(Wish(id: "a", title: "효도 여행", companions: [WishCompanion(name: "엄마")]))
        let mom = try XCTUnwrap(sut.fetchRecentCompanions().first)

        // When: 칩으로 고른 사람 / 새 id 로 " 엄마 "를 직접 적음
        try add(Wish(id: "b", title: "김치찌개", companions: [mom]))
        try add(Wish(id: "c", title: "꽃구경", companions: [WishCompanion(name: " 엄마 ")]))

        // Then
        let personIds = Set(try database.snapshot().companions.map(\.personId))
        XCTAssertEqual(personIds, [mom.personId])
        XCTAssertEqual(Set(sut.fetchCompanionWishes(personId: mom.personId).map(\.id)), ["a", "b", "c"])
    }

    func test_GH122_TC14_영문이름은_대소문자와공백을무시하고같은사람이다() throws {
        // Given
        try add(Wish(id: "a", title: "서핑", companions: [WishCompanion(name: "Ji  Eun")]))
        let jieun = try XCTUnwrap(sut.fetchRecentCompanions().first)

        // When
        try add(Wish(id: "b", title: "캠핑", companions: [WishCompanion(name: "ji eun")]))

        // Then
        XCTAssertEqual(sut.fetchWish(id: "b")?.companions.first?.personId, jieun.personId)
    }

    // MARK: TC-15

    func test_GH122_TC15_사람을붙여저장하면_linkedUid는비어있다() throws {
        // When
        var wish = try add(Wish(id: "w", title: "제주", companions: [WishCompanion(name: "엄마")]))
        wish.companions.append(WishCompanion(name: "지은"))
        try update(wish)

        // Then
        let rows = try database.snapshot().companions
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows.allSatisfy { $0.linkedUid == nil })
    }

    // MARK: 로그아웃 "이 기기에서 지우기"

    func test_GH122_이기기에서지우기는_사람줄도지운다() throws {
        // Given
        try add(Wish(id: "w", title: "제주", companions: [WishCompanion(name: "엄마")]))

        // When
        _ = try sut.eraseAllLocalWishes().get()

        // Then
        XCTAssertTrue(try database.snapshot().companions.isEmpty)
    }
}
