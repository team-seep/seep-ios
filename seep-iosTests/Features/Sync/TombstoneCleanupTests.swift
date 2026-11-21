import XCTest


@testable import seep_ios

/// 삭제 표시 정리 (GH-93 4단계 R-42 ~ R-45, 설계 §6.5). 기기 두 대 = 메모리 DB 두 개 + 메모리 서버 하나
final class TombstoneCleanupTests: XCTestCase {
    private var server: FakeSyncServer!
    private var deviceA: SyncTestDevice!
    private var deviceB: SyncTestDevice!
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = FakeSyncServer()
        deviceA = try SyncTestDevice(server: server, clock: start)
        deviceB = try SyncTestDevice(server: server, clock: start.addingTimeInterval(5))
    }

    override func tearDown() {
        server = nil
        deviceA = nil
        deviceB = nil
        super.tearDown()
    }

    private func signInBoth(uid: String = "uid-1") async {
        _ = await deviceA.engine.startSession(uid: uid) { _, _ in }
        _ = await deviceB.engine.startSession(uid: uid) { _, _ in }
    }

    /// 삭제 표시까지 포함해 DB 에 남은 줄 수
    private func rowCount(_ device: SyncTestDevice, table: String, wishId: String) throws -> Int {
        let snapshot = try device.database.snapshot()
        switch table {
        case "wish": return snapshot.wishes.filter { $0.id == wishId }.count
        case "wishStep": return snapshot.steps.filter { $0.wishId == wishId }.count
        case "wishSaving": return snapshot.savings.filter { $0.wishId == wishId }.count
        default:
            XCTFail("모르는 테이블 \(table)")
            return 0
        }
    }

    private func lastPullParameters(_ device: SyncTestDevice) -> [ParameterName: Any]? {
        device.logManager.sentEvents.last { $0.name == .syncPull }?.extraParameters
    }

    // MARK: TC-40

    func test_GH93_TC40_올렸고90일지난삭제표시는_하위줄까지물리삭제된다() async throws {
        // Given: 모은 돈 기록이 있는 위시를 지우고 올렸다
        await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        _ = try deviceA.repository.addSaving(wishId: "w1", amount: 1000).get()
        deviceA.repository.deleteWish(id: "w1")
        await deviceA.engine.sync(trigger: .manual)
        XCTAssertEqual(try rowCount(deviceA, table: "wish", wishId: "w1"), 1)

        // When
        deviceA.tick(91 * day)
        await deviceA.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(try rowCount(deviceA, table: "wish", wishId: "w1"), 0)
        XCTAssertEqual(try rowCount(deviceA, table: "wishSaving", wishId: "w1"), 0)
        XCTAssertEqual(lastPullParameters(deviceA)?[.purgeCount] as? Int, 2)
    }

    func test_GH93_TC40_90일안된삭제표시는_남는다() async throws {
        // Given: w2 는 지운 지 91일, w1 은 10일
        await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        _ = try deviceA.repository.addWish(Wish(id: "w2", title: "오래전 지움")).get()
        deviceA.repository.deleteWish(id: "w2")
        await deviceA.engine.sync(trigger: .manual)
        deviceA.tick(81 * day)
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "최근 지움")).get()
        deviceA.repository.deleteWish(id: "w1")
        deviceA.tick(10 * day)

        // When
        await deviceA.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(try rowCount(deviceA, table: "wish", wishId: "w1"), 1)
        XCTAssertEqual(try rowCount(deviceA, table: "wish", wishId: "w2"), 0)
    }

    func test_GH93_TC40_아직안올린삭제표시는_90일지나도남는다() throws {
        // Given: 아웃박스에 남은(서버에 아직 없는) 삭제 표시
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        deviceA.repository.deleteWish(id: "w1")
        XCTAssertEqual(deviceA.store.pendingCount(), 1)

        // When
        deviceA.store.purgeTombstones(deletedBefore: start.addingTimeInterval(91 * day))

        // Then
        XCTAssertEqual(try rowCount(deviceA, table: "wish", wishId: "w1"), 1)
    }

    func test_GH93_TC40_어느계정에도묶인적없는기기는_로그인없이도정리된다() async throws {
        // Given: 비회원
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        deviceA.repository.deleteWish(id: "w1")

        // When
        deviceA.tick(91 * day)
        await deviceA.engine.sync(trigger: .launch)

        // Then
        XCTAssertEqual(try rowCount(deviceA, table: "wish", wishId: "w1"), 0)
    }

    func test_GH93_TC40_계정에묶인채로그아웃한기기는_삭제표시를남긴다() async throws {
        // Given: 로그아웃하면 아웃박스가 비지만, 다시 로그인할 때 삭제 표시를 올려야 한다
        await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        await deviceA.engine.endSession(unbindDevice: false, flushPending: false)
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        deviceA.repository.deleteWish(id: "w1")

        // When
        deviceA.tick(91 * day)
        await deviceA.engine.sync(trigger: .launch)

        // Then
        XCTAssertEqual(try rowCount(deviceA, table: "wish", wishId: "w1"), 1)
    }

    // MARK: TC-41

    func test_GH93_TC41_마지막으로받은지80일넘으면_전체다시받아_서버에서사라진위시를지운다() async throws {
        // Given: 두 기기가 w1·w2 를 받았다
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "지울 것")).get()
        _ = try deviceA.repository.addWish(Wish(id: "w2", title: "남을 것")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)
        deviceB.photoStorage.existingFileNames.insert("w1-photo.jpg")

        // When: B 를 오래 안 켠 사이 A 가 w1 을 지웠고, 그 삭제 표시는 서버에서 TTL 로 사라졌다.
        // B 는 그사이 오프라인에서 w3 를 만들었다
        deviceA.tick(day)
        deviceA.repository.deleteWish(id: "w1")
        await deviceA.engine.sync(trigger: .manual)
        server.purge(.wish, id: "w1")
        deviceB.tick(100 * day)
        _ = try deviceB.repository.addWish(Wish(id: "w3", title: "오프라인에서 만듦")).get()
        await deviceB.engine.sync(trigger: .launch)

        // Then
        XCTAssertNil(deviceB.repository.fetchWish(id: "w1"))
        XCTAssertEqual(try rowCount(deviceB, table: "wish", wishId: "w1"), 0)
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "w2"))
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "w3"))
        XCTAssertNotNil(server.documents[.wish]?["w3"])
        XCTAssertTrue(deviceB.notifications.cancelledWishes.contains { $0.id == "w1" })
        XCTAssertTrue(deviceB.photoStorage.deletePhotosCalledWishIds.contains("w1"))
        XCTAssertEqual(lastPullParameters(deviceB)?[.isFullPull] as? Int, 1)
    }

    func test_GH93_TC41_80일안이면_증분으로받고_서버에없는로컬줄을지우지않는다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: 서버에서 문서가 사라져도 80일이 안 됐으면 전체를 받지 않는다
        server.purge(.wish, id: "w1")
        deviceB.tick(79 * day)
        await deviceB.engine.sync(trigger: .launch)

        // Then
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "w1"))
        XCTAssertEqual(lastPullParameters(deviceB)?[.isFullPull] as? Int, 0)
    }

    // MARK: TC-48

    func test_GH93_TC48_삭제표시를올리면_90일뒤TTL시각이같이가고_살아있는문서에는없다() async throws {
        // Given
        await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "지울 것")).get()
        _ = try deviceA.repository.addWish(Wish(id: "w2", title: "남을 것")).get()
        deviceA.tick(60)
        deviceA.repository.deleteWish(id: "w1")

        // When
        await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertEqual(server.documents[.wish]?["w1"]?.purgeAt, deviceA.clock.addingTimeInterval(90 * day))
        XCTAssertNil(server.documents[.wish]?["w2"]?.purgeAt)
    }

    // MARK: TC-50

    func test_GH93_TC50_다른기기에서지운위시를받으면_이기기사진파일도지운다() async throws {
        // Given
        await signInBoth()
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When
        deviceA.tick(60)
        deviceA.repository.deleteWish(id: "w1")
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertNil(deviceB.repository.fetchWish(id: "w1"))
        XCTAssertEqual(deviceB.photoStorage.deletePhotosCalledWishIds, ["w1"])
    }

    // MARK: TC-51

    func test_GH93_TC51_부모없는하위삭제표시는_미루지않아커서가막히지않는다() async throws {
        // Given: 위시의 삭제 표시가 TTL 로 먼저 지워지고, 하위 줄의 삭제 표시만 남았다
        await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        server.put(.wishStep, id: "s1", fields: ["wishId": .text("gone"), "updatedAt": .double(1), "deletedAt": .double(1)])

        // When
        await deviceA.engine.sync(trigger: .manual)

        // Then
        XCTAssertNotNil(deviceA.store.cursor(.wishStep))
        XCTAssertEqual(try rowCount(deviceA, table: "wishStep", wishId: "gone"), 0)
    }

    func test_GH93_TC51_부모없는살아있는하위줄은_다음사이클로미룬다() async throws {
        // Given: 부모 위시가 아직 안 올라왔다 (TC-29 와 같은 경우)
        await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        server.put(.wishStep, id: "s1", fields: ["wishId": .text("later"), "updatedAt": .double(1), "deletedAt": .null])

        // When
        await deviceA.engine.sync(trigger: .manual)

        // Then
        XCTAssertNil(deviceA.store.cursor(.wishStep))
    }
}
