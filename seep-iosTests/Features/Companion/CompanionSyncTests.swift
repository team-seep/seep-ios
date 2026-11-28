import XCTest

@testable import seep_ios

/// 함께할 사람 서버 저장 (GH-122 R-10, R-12, 설계 §4.1). 기기 두 대 = 메모리 DB 두 개 + 메모리 서버 하나
final class CompanionSyncTests: XCTestCase {
    private var server: FakeSyncServer!
    private var deviceA: SyncTestDevice!
    private var deviceB: SyncTestDevice!
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = FakeSyncServer()
        let photoServer = FakePhotoServer()
        deviceA = try SyncTestDevice(server: server, photoServer: photoServer, clock: start)
        deviceB = try SyncTestDevice(server: server, photoServer: photoServer, clock: start.addingTimeInterval(5))
    }

    override func tearDown() {
        server = nil
        deviceA = nil
        deviceB = nil
        super.tearDown()
    }

    private func signInBoth() async {
        _ = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        _ = await deviceB.engine.startSession(uid: "uid-1") { _, _ in }
    }

    // MARK: TC-13

    func test_GH122_TC13_A에서엄마를붙이고동기화하면_B상세와모아보기에보이고_빼면B에서도빠진다() async throws {
        // Given
        await signInBoth()
        let mom = WishCompanion(name: "엄마")
        var wish = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", companions: [mom, WishCompanion(name: "지은")])).get()

        // When
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.companions.map(\.name), ["엄마", "지은"])
        XCTAssertEqual(deviceB.repository.fetchCompanionWishes(personId: mom.personId).map(\.id), ["w1"])

        // When: A에서 엄마를 뺀다
        deviceA.tick(60)
        wish.companions.removeAll { $0.personId == mom.personId }
        _ = try deviceA.repository.updateWish(wish).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.companions.map(\.name), ["지은"])
        XCTAssertTrue(deviceB.repository.fetchCompanionWishes(personId: mom.personId).isEmpty)
        let removed = try deviceB.database.snapshot().companions.first { $0.personId == mom.personId }
        XCTAssertNotNil(removed?.deletedAt)
    }

    func test_GH122_TC13_다른기기에서받은같은personId는_같은사람으로모인다() async throws {
        // Given: A에서 엄마를 붙여 B로 보낸다
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", companions: [WishCompanion(name: "엄마")])).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: B에서 "엄마"를 직접 적어 새 위시에 붙인다
        _ = try deviceB.repository.addWish(Wish(id: "w2", title: "김치찌개", companions: [WishCompanion(name: "엄마")])).get()

        // Then
        let mom = try XCTUnwrap(deviceB.repository.fetchRecentCompanions().first)
        XCTAssertEqual(Set(deviceB.repository.fetchCompanionWishes(personId: mom.personId).map(\.id)), ["w1", "w2"])
    }

    // MARK: TC-15

    func test_GH122_TC15_올린사람문서의linkedUid는_null이다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", companions: [WishCompanion(name: "엄마")])).get()

        // When
        await deviceA.engine.sync(trigger: .manual)

        // Then
        let uploaded = try XCTUnwrap(server.documents[.wishCompanion]?.values.first)
        XCTAssertEqual(uploaded.fields["linkedUid"], .null)
        XCTAssertEqual(uploaded.fields["name"], .text("엄마"))
        XCTAssertEqual(SyncCollection.wishCompanion.collectionName, "wishCompanions")
    }

    // MARK: TC-16

    func test_GH122_TC16_비회원은_로컬에서그대로보이고서버요청이없다() async throws {
        // Given
        let mom = WishCompanion(name: "엄마")
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", companions: [mom])).get()

        // When
        let report = await deviceA.engine.sync(trigger: .launch)

        // Then
        XCTAssertTrue(report.isSkipped)
        XCTAssertEqual(server.pushCallCount, 0)
        XCTAssertNil(server.documents[.wishCompanion])
        XCTAssertEqual(deviceA.repository.fetchWish(id: "w1")?.companions.map(\.name), ["엄마"])
        XCTAssertEqual(deviceA.repository.fetchCompanionWishes(personId: mom.personId).map(\.id), ["w1"])
    }

    // MARK: 마이그레이션

    func test_GH122_v12기기에서올리면_v13이돌고_사람줄도아웃박스에쌓인다() throws {
        // Given: 지난 출시(v12까지) DB
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v12")

        // When
        try database.migrateToLatest()
        let repository = WishRepositoryImpl(database: database)
        _ = try repository.addWish(Wish(id: "w1", title: "제주", companions: [WishCompanion(name: "엄마")])).get()

        // Then
        let queued = SyncStore(database: database).pendingDocuments(limit: 100)?.documents.map(\.collection) ?? []
        XCTAssertTrue(queued.contains(.wishCompanion))
        XCTAssertEqual(try database.snapshot().companions.count, 1)
    }
}
