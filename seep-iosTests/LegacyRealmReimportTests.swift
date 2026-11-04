import XCTest

@testable import seep_ios

/// Realm → GRDB 이전 안전장치: 결정적 id·원격 재이전 (GH-96 R-1 ~ R-5, R-15). 임시 Realm 파일과 메모리 DB 로 돌린다
final class LegacyRealmReimportTests: XCTestCase {
    private var fixture: LegacyRealmFixture!
    private var database: AppDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()
        fixture = try LegacyRealmFixture()
        database = try AppDatabase.makeInMemory()
    }

    override func tearDown() {
        fixture.remove()
        database = nil
        super.tearDown()
    }

    private var repository: WishRepositoryImpl {
        WishRepositoryImpl(database: database)
    }

    private func importOnce() throws {
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)
    }

    /// 업데이트 뒤 어떤 이유로 GRDB 에서 위시 줄이 사라진 상황을 만든다(하위 줄은 CASCADE 로 같이 빠진다)
    private func loseWish(id: String) throws {
        let record = try XCTUnwrap(database.snapshot().wishes.first { $0.id == id })
        try database.deleteRecord(record)
    }

    // MARK: GH-96 TC1

    func test_GH96_TC1_같은id위시가여럿인Realm을두번읽으면_두번모두같은새id가나온다() throws {
        // Given
        try fixture.seed([
            Wish(id: "dup", title: "첫째", steps: [WishStep(id: "step-dup", title: "A", order: 0)]),
            Wish(id: "dup", title: "둘째", steps: [WishStep(id: "step-dup", title: "B", order: 0)])
        ])
        let other = try AppDatabase.makeInMemory()

        // When
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)
        try fixture.importer().importIfNeeded(into: other, markWhenNoRealmFile: true)

        // Then
        let first = try database.snapshot()
        let second = try other.snapshot()
        XCTAssertEqual(Set(first.wishes.map(\.id)), Set(second.wishes.map(\.id)))
        XCTAssertEqual(Set(first.steps.map(\.id)), Set(second.steps.map(\.id)))
        XCTAssertEqual(Set(first.wishes.map(\.id)).count, 2)
    }

    // MARK: GH-96 TC2

    func test_GH96_TC2_id가빈위시와하위줄도_두번읽으면같은id를받는다() throws {
        // Given
        try fixture.seed([
            Wish(id: "a", title: "첫째", notifications: [SeepNotification(type: .dayAgo)],
                 steps: [WishStep(id: "s", title: "단계", order: 0)],
                 targetAmount: 1_000, savings: [WishSaving(id: "v", amount: 100, createdAt: LegacyRealmFixture.day(1))]),
            Wish(id: "b", title: "둘째")
        ]) { dto in
            dto._id = ""
            dto.steps.forEach { $0._id = "" }
            dto.savings.forEach { $0._id = "" }
            dto.notifications.forEach { $0.id = "" }
        }
        let other = try AppDatabase.makeInMemory()

        // When
        try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)
        try fixture.importer().importIfNeeded(into: other, markWhenNoRealmFile: true)

        // Then
        let first = try database.snapshot()
        let second = try other.snapshot()
        XCTAssertEqual(Set(first.wishes.map(\.id)), Set(second.wishes.map(\.id)))
        XCTAssertEqual(first.steps.map(\.id), second.steps.map(\.id))
        XCTAssertEqual(first.savings.map(\.id), second.savings.map(\.id))
        XCTAssertEqual(first.notifications.map(\.id), second.notifications.map(\.id))
        XCTAssertFalse(first.wishes.contains { $0.id.isEmpty })
    }

    // MARK: GH-96 TC3

    func test_GH96_TC3_빠진위시가있을때재이전하면_빠진위시와하위줄만다시들어온다() throws {
        // Given
        try fixture.seed([LegacyRealmFixture.fullWish(id: "lost"), Wish(id: "kept", title: "남은 위시")])
        try importOnce()
        try loseWish(id: "lost")

        // When
        let report = try XCTUnwrap(fixture.importer().reimportMissing(into: database, token: "t1"))

        // Then
        XCTAssertEqual(report.restoredWishIds, ["lost"])
        XCTAssertEqual(report.restoredRowCount, 6) // 단계 2 · 저금 2 · 알림 2
        let snapshot = try database.snapshot()
        XCTAssertEqual(snapshot.wishes.count, 2)
        let restored = try XCTUnwrap(repository.fetchWish(id: "lost"))
        XCTAssertEqual(restored.title, "양양에서 서핑 배우기")
        XCTAssertEqual(restored.steps.map(\.id), ["step-a", "step-b"])
        XCTAssertEqual(restored.savings.count, 2)
        XCTAssertEqual(restored.notifications.map(\.id), ["noti-1", "noti-2"])
    }

    // MARK: GH-96 TC4

    func test_GH96_TC4_업데이트뒤에고친위시는_재이전후에도고친값그대로다() throws {
        // Given
        try fixture.seed([Wish(id: "edited", title: "원래 제목"), Wish(id: "lost", title: "빠진 위시")])
        try importOnce()
        var edited = try XCTUnwrap(repository.fetchWish(id: "edited"))
        edited.title = "고친 제목"
        _ = try repository.updateWish(edited).get()
        try loseWish(id: "lost")

        // When
        _ = try fixture.importer().reimportMissing(into: database, token: "t1")

        // Then
        XCTAssertEqual(repository.fetchWish(id: "edited")?.title, "고친 제목")
        XCTAssertNotNil(repository.fetchWish(id: "lost"))
    }

    // MARK: GH-96 TC5

    func test_GH96_TC5_업데이트뒤에지운위시는_재이전후에도보이지않는다() throws {
        // Given
        try fixture.seed([Wish(id: "deleted", title: "지운 위시"), Wish(id: "kept", title: "남은 위시")])
        try importOnce()
        repository.deleteWish(id: "deleted")

        // When
        _ = try fixture.importer().reimportMissing(into: database, token: "t1")

        // Then
        XCTAssertNil(repository.fetchWish(id: "deleted"))
        XCTAssertNotNil(try database.snapshot().wishes.first { $0.id == "deleted" }?.deletedAt)
    }

    // MARK: GH-96 TC6

    func test_GH96_TC6_업데이트뒤에새로적은위시는_재이전후에도그대로있다() throws {
        // Given
        try fixture.seed([Wish(id: "old", title: "예전 위시")])
        try importOnce()
        _ = try repository.addWish(Wish(id: "new", title: "새 위시")).get()

        // When
        _ = try fixture.importer().reimportMissing(into: database, token: "t1")

        // Then
        XCTAssertEqual(repository.fetchWish(id: "new")?.title, "새 위시")
        XCTAssertNotNil(repository.fetchWish(id: "old"))
    }

    // MARK: GH-96 TC7

    func test_GH96_TC7_같은토큰으로는한번만돌고_토큰을바꾸면다시돈다() throws {
        // Given
        try fixture.seed([Wish(id: "lost", title: "빠진 위시")])
        try importOnce()
        try loseWish(id: "lost")

        // When
        let first = try fixture.importer().reimportMissing(into: database, token: "t1")
        try loseWish(id: "lost")
        let sameToken = try fixture.importer().reimportMissing(into: database, token: "t1")
        let newToken = try fixture.importer().reimportMissing(into: database, token: "t2")

        // Then
        XCTAssertEqual(first?.restoredWishIds, ["lost"])
        XCTAssertNil(sameToken)
        XCTAssertEqual(newToken?.restoredWishIds, ["lost"])
        XCTAssertEqual(try database.snapshot().metadata[LegacyRealmImporter.MetadataKey.reimportToken], "t2")
    }

    // MARK: GH-96 TC8

    func test_GH96_TC8_토큰이비어있으면_재이전하지않는다() throws {
        // Given
        try fixture.seed([Wish(id: "lost", title: "빠진 위시")])
        try importOnce()
        try loseWish(id: "lost")

        // When
        let report = try fixture.importer().reimportMissing(into: database, token: "")

        // Then
        XCTAssertNil(report)
        XCTAssertTrue(try database.snapshot().wishes.isEmpty)
    }

    func test_GH96_TC8_Realm파일이없으면_재이전하지않는다() throws {
        // Given: 신규 설치
        try importOnce()

        // When
        let report = try fixture.importer().reimportMissing(into: database, token: "t1")

        // Then
        XCTAssertNil(report)
        XCTAssertNil(try database.snapshot().metadata[LegacyRealmImporter.MetadataKey.reimportToken])
    }

    func test_GH96_TC8_1회이전이끝나기전에는_재이전하지않는다() throws {
        // Given: Realm 은 있지만 1회 이전 전
        try fixture.seed([Wish(id: "wish", title: "위시")])

        // When
        let report = try fixture.importer().reimportMissing(into: database, token: "t1")

        // Then
        XCTAssertNil(report)
        XCTAssertTrue(try database.snapshot().wishes.isEmpty)
    }

    // MARK: GH-96 TC9

    func test_GH96_TC9_재이전도중실패하면_DB는그대로이고_다음실행에서다시시도한다() throws {
        // Given: 이전 뒤 원본을 읽을 수 없게 된다
        try fixture.seed([Wish(id: "lost", title: "빠진 위시")])
        try importOnce()
        try loseWish(id: "lost")
        let brokenImporter = try fixture.brokenImporter()

        // When
        XCTAssertThrowsError(try brokenImporter.reimportMissing(into: database, token: "t1"))

        // Then
        let failed = try database.snapshot()
        XCTAssertTrue(failed.wishes.isEmpty)
        XCTAssertNil(failed.metadata[LegacyRealmImporter.MetadataKey.reimportToken])

        // When: 다음 실행
        let report = try fixture.importer().reimportMissing(into: database, token: "t1")

        // Then
        XCTAssertEqual(report?.restoredWishIds, ["lost"])
    }

    // MARK: GH-96 TC10

    func test_GH96_TC10_재이전으로돌아온위시는_카테고리맨위에온다() throws {
        // Given
        try fixture.seed([
            Wish(id: "older", title: "예전", createdAt: LegacyRealmFixture.day(1)),
            Wish(id: "lost", title: "빠진 위시", createdAt: LegacyRealmFixture.day(2)),
            Wish(id: "newer", title: "최근", createdAt: LegacyRealmFixture.day(3))
        ])
        try importOnce()
        try loseWish(id: "lost")

        // When
        _ = try fixture.importer().reimportMissing(into: database, token: "t1")

        // Then
        let ordered = repository.fetchWishes(category: .wantToDo, sort: .manualOrder, isOnlyFinished: false)
        XCTAssertEqual(ordered.map(\.id), ["lost", "newer", "older"])
    }

    // MARK: GH-96 TC16

    func test_GH96_TC16_이전실패중에새로적은위시는_이전이끝난뒤에도예전위시와함께남는다() throws {
        // Given: 이전이 끝나지 않은 상태에서 새 위시를 적는다
        try fixture.seed([Wish(id: "old", title: "예전 위시")])
        _ = try repository.addWish(Wish(id: "new", title: "새 위시")).get()

        // When: 다시 시도
        let report = try fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true)

        // Then
        XCTAssertEqual(report?.wishCount, 1)
        XCTAssertNotNil(repository.fetchWish(id: "old"))
        XCTAssertNotNil(repository.fetchWish(id: "new"))
    }

    // MARK: GH-96 TC21

    func test_GH96_TC21_이전결과에_원본Realm위시수와옮긴위시수가같이남는다() throws {
        // Given
        try fixture.seed([Wish(id: "dup", title: "첫째"), Wish(id: "dup", title: "둘째"), Wish(id: "c", title: "셋째")])

        // When
        let report = try XCTUnwrap(fixture.importer().importIfNeeded(into: database, markWhenNoRealmFile: true))

        // Then
        XCTAssertEqual(report.realmWishCount, 3)
        XCTAssertEqual(report.wishCount, 3)
    }
}
