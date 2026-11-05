import XCTest

@testable import seep_ios

/// 메모리 Firestore 대역. `merge: true` 쓰기와 배치마다 같은 `serverUpdatedAt`을 흉내 낸다
final class FakeSyncServer: RemoteWishStore, @unchecked Sendable {
    struct Stored {
        var fields: [String: SyncValue]
        var serverUpdatedAt: RemoteTimestamp
        /// Firestore TTL 필드. 삭제 표시 문서에만 있다
        var purgeAt: Date?
    }

    private(set) var documents: [SyncCollection: [String: Stored]] = [:]
    private(set) var pushCallCount = 0
    var failPush = false
    private var tick: Int64 = 0

    struct Failure: Error {}

    func push(_ documents: [SyncDocument], metadata: SyncMetadata) async throws {
        if failPush { throw Failure() }
        pushCallCount += 1
        tick += 1
        let timestamp = RemoteTimestamp(seconds: tick, nanoseconds: 0)
        for document in documents {
            var stored = self.documents[document.collection]?[document.id]?.fields ?? [:]
            stored.merge(document.fields) { _, new in new }
            self.documents[document.collection, default: [:]][document.id] = Stored(
                fields: stored,
                serverUpdatedAt: timestamp,
                purgeAt: document.isDeleted ? metadata.purgeAt : nil
            )
        }
    }

    func pull(_ collection: SyncCollection, uid: String, after cursor: RemoteTimestamp?) async throws -> [SyncDocument] {
        (documents[collection] ?? [:])
            .filter { entry in cursor.map { entry.value.serverUpdatedAt > $0 } ?? true }
            .sorted { ($0.value.serverUpdatedAt, $0.key) < ($1.value.serverUpdatedAt, $1.key) }
            .map { SyncDocument(collection: collection, id: $0.key, fields: $0.value.fields, serverUpdatedAt: $0.value.serverUpdatedAt) }
    }

    /// TTL 정책이 문서를 지운 것처럼 서버에서 뺀다
    func purge(_ collection: SyncCollection, id: String) {
        documents[collection]?[id] = nil
    }

    /// 다른 앱 버전이 쓴 문서처럼 서버에 바로 넣는다
    func put(_ collection: SyncCollection, id: String, fields: [String: SyncValue]) {
        tick += 1
        documents[collection, default: [:]][id] = Stored(fields: fields, serverUpdatedAt: RemoteTimestamp(seconds: tick, nanoseconds: 0))
    }
}

/// 기기 한 대: 메모리 DB + 실제 저장소·엔진
/// Storage 대역. 경로 `wishPhotos/{uid}/{fileName}`를 키로 바이트를 둔다
final class FakePhotoServer: RemotePhotoStore, @unchecked Sendable {
    private(set) var files: [String: Data] = [:]
    private(set) var uploadCallCount = 0
    private(set) var downloadRequests: [String] = []
    var failUpload = false

    func upload(fileURL: URL, fileName: String, uid: String) async throws {
        uploadCallCount += 1
        if failUpload { throw FakeSyncServer.Failure() }
        files["wishPhotos/\(uid)/\(fileName)"] = Data(fileName.utf8)
    }

    func download(fileName: String, uid: String) async throws -> Data {
        downloadRequests.append(fileName)
        guard let data = files["wishPhotos/\(uid)/\(fileName)"] else { throw RemotePhotoError.notFound }
        return data
    }
}

final class SyncTestDevice {
    let database: AppDatabase
    let repository: WishRepositoryImpl
    let store: SyncStore
    let engine: SyncEngine
    let notifications = MockNotificationManager()
    let logManager = MockLogManager()
    let photoStorage = MockWishPhotoStorage()
    private(set) var widgetReloadCount = 0
    private(set) var photosDidDownloadCount = 0
    var clock: Date

    init(server: FakeSyncServer, photoServer: FakePhotoServer = FakePhotoServer(), clock: Date) throws {
        self.clock = clock
        database = try AppDatabase.makeInMemory()
        store = SyncStore(database: database)
        var nowBox: (() -> Date)?
        repository = WishRepositoryImpl(database: database, now: { nowBox?() ?? Date() })
        var reload: (() -> Void)?
        var photosDownloaded: (() -> Void)?
        engine = SyncEngine(dependency: .init(
            store: store,
            remote: server,
            photos: photoServer,
            photoStorage: photoStorage,
            photosDidDownload: { photosDownloaded?() },
            isEnabled: { true },
            wishRepository: repository,
            notificationManager: notifications,
            reloadWidgets: { reload?() },
            logManager: logManager,
            now: { nowBox?() ?? Date() }
        ))
        nowBox = { [unowned self] in self.clock }
        reload = { [unowned self] in self.widgetReloadCount += 1 }
        photosDownloaded = { [unowned self] in self.photosDidDownloadCount += 1 }
    }

    /// 사진을 붙인 위시를 저장한다(파일은 이미 저장된 것으로 본다)
    func addWishWithPhoto(id: String, fileName: String) throws {
        photoStorage.existingFileNames.insert(fileName)
        _ = try repository.addWish(Wish(id: id, title: "사진 \(id)", photoFileName: fileName)).get()
    }

    func tick(_ seconds: TimeInterval = 60) {
        clock = clock.addingTimeInterval(seconds)
    }

    /// 아웃박스에 쌓인 줄의 테이블 (같은 줄은 한 번)
    func outboxTables() -> Set<String> {
        Set(store.pendingDocuments(limit: 100)?.documents.map(\.collection.tableName) ?? [])
    }
}

/// 동기화 v1 (GH-93 R-32 ~ R-39, 설계 §5·§6). 기기 두 대 = 메모리 DB 두 개 + 메모리 서버 하나
final class SyncEngineTests: XCTestCase {
    private var server: FakeSyncServer!
    private var photoServer: FakePhotoServer!
    private var deviceA: SyncTestDevice!
    private var deviceB: SyncTestDevice!
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = FakeSyncServer()
        photoServer = FakePhotoServer()
        deviceA = try SyncTestDevice(server: server, photoServer: photoServer, clock: start)
        deviceB = try SyncTestDevice(server: server, photoServer: photoServer, clock: start.addingTimeInterval(5))
    }

    override func tearDown() {
        server = nil
        photoServer = nil
        deviceA = nil
        deviceB = nil
        super.tearDown()
    }

    private func signInBoth(uid: String = "uid-1") async {
        let outcomeA = await deviceA.engine.startSession(uid: uid) { _, _ in }
        let outcomeB = await deviceB.engine.startSession(uid: uid) { _, _ in }
        XCTAssertEqual(outcomeA, .merged)
        XCTAssertEqual(outcomeB, .merged)
    }

    // MARK: TC-23

    func test_GH93_TC23_앱과위젯어느경로로쓰든_아웃박스에줄이쌓인다() throws {
        // Given / When: 앱 저장소로 위시·단계·저금·일지, 위젯 저장소로 단계 체크
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", steps: [WishStep(id: "s1", title: "항공권", order: 0)])).get()
        _ = try deviceA.repository.addSaving(wishId: "w1", amount: 1_000).get()
        _ = try deviceA.repository.addJournal(wishId: "w1", text: "오늘 검색").get()

        // Then
        XCTAssertEqual(deviceA.outboxTables(), ["wish", "wishStep", "wishSaving", "wishJournal"])

        // When: 위젯 프로세스의 쓰기만 따로
        deviceA.store.clearOutbox()
        let widgetRepository = WidgetCheckRepositoryImpl(database: deviceA.database)
        _ = try widgetRepository.checkStep(wishId: "w1", stepId: "s1").get()

        // Then
        XCTAssertTrue(deviceA.outboxTables().contains("wishStep"))
    }

    // MARK: TC-24

    func test_GH93_TC24_push가성공하면_아웃박스가비고_실패하면그대로남는다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()

        // When: 실패
        server.failPush = true
        let failed = await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertEqual(failed.failedStage, "push")
        XCTAssertEqual(deviceA.store.pendingCount(), 1)

        // When: 성공
        server.failPush = false
        let succeeded = await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertNil(succeeded.failedStage)
        XCTAssertEqual(succeeded.pushed, 1)
        XCTAssertEqual(deviceA.store.pendingCount(), 0)
        XCTAssertNotNil(server.documents[.wish]?["w1"])
    }

    // MARK: TC-25

    func test_GH93_TC25_A에서만든위시가_B에서받아진다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", steps: [WishStep(id: "s1", title: "항공권", order: 0)])).get()
        await deviceA.engine.sync(trigger: .manual)

        // When
        let report = await deviceB.engine.sync(trigger: .manual)

        // Then
        let wish = deviceB.repository.fetchWish(id: "w1")
        XCTAssertEqual(wish?.title, "제주")
        XCTAssertEqual(wish?.steps.map(\.title), ["항공권"])
        XCTAssertEqual(report.changedWishIds, ["w1"])
        XCTAssertEqual(deviceB.widgetReloadCount, 1)
    }

    // MARK: TC-26

    func test_GH93_TC26_두기기에서같은위시를고치면_나중에고친쪽이이긴다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: A 가 먼저, B 가 나중에 고친다(오프라인), 그다음 A·B 순으로 올린다
        deviceA.tick(60)
        var fromA = try XCTUnwrap(deviceA.repository.fetchWish(id: "w1"))
        fromA.title = "A 제목"
        _ = try deviceA.repository.updateWish(fromA).get()
        deviceB.tick(120)
        var fromB = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        fromB.title = "B 제목"
        _ = try deviceB.repository.updateWish(fromB).get()
        await deviceB.engine.sync(trigger: .manual)
        await deviceA.engine.sync(trigger: .manual) // A 의 옛 값이 서버의 B 값을 덮는다
        await deviceB.engine.sync(trigger: .manual) // B 는 받은 옛 값보다 자기 값이 새것이라 다시 올릴 줄을 쌓는다
        await deviceB.engine.sync(trigger: .localChange)

        // Then: 두 기기 모두 나중에 고친 B 값으로 맞춰진다
        await deviceA.engine.sync(trigger: .manual)
        XCTAssertEqual(deviceA.repository.fetchWish(id: "w1")?.title, "B 제목")
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.title, "B 제목")
    }

    // MARK: TC-27

    func test_GH93_TC27_한쪽이지우고다른쪽이나중에고쳐도_삭제가이긴다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When: A 가 지우고, B 가 더 나중에 고친다
        deviceA.tick(60)
        deviceA.repository.deleteWish(id: "w1")
        deviceB.tick(600)
        var fromB = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        fromB.title = "고침"
        _ = try deviceB.repository.updateWish(fromB).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual) // B 의 고친 값이 서버의 삭제 표시를 덮는다
        await deviceA.engine.sync(trigger: .manual) // A 는 지운 줄이 서버에 살아 있으면 삭제를 다시 올릴 줄을 쌓는다
        await deviceA.engine.sync(trigger: .localChange)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertNil(deviceA.repository.fetchWish(id: "w1"))
        XCTAssertNil(deviceB.repository.fetchWish(id: "w1"))
        XCTAssertFalse(server.documents[.wish]?["w1"]?.fields["deletedAt"]?.isNull ?? true)
    }

    // MARK: TC-28

    func test_GH93_TC28_받아서적용한줄은_다시올리지않는다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        let pushesBefore = server.pushCallCount

        // When
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.store.pendingCount(), 0)
        let again = await deviceB.engine.sync(trigger: .manual)
        XCTAssertEqual(again.pushed, 0)
        XCTAssertEqual(server.pushCallCount, pushesBefore)
    }

    // MARK: TC-29

    func test_GH93_TC29_하위줄이부모보다먼저와도_다음사이클에적용된다() async throws {
        // Given: 서버에 단계만 먼저 있다
        await signInBoth()
        let stepFields: [String: SyncValue] = [
            "wishId": .text("w9"), "title": .text("항공권"), "isDone": .integer(0), "order": .integer(0),
            "updatedAt": .double(800_000_100), "deletedAt": .null
        ]
        server.put(.wishStep, id: "s9", fields: stepFields)
        let first = await deviceB.engine.sync(trigger: .manual)
        XCTAssertNil(first.failedStage)
        XCTAssertNil(deviceB.repository.fetchWish(id: "w9"))

        // When: 부모 위시가 나중에 온다
        _ = try deviceA.repository.addWish(Wish(id: "w9", title: "오사카")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w9")?.steps.map(\.id), ["s9"])
    }

    // MARK: TC-30

    func test_GH93_TC30_비회원위시가있는기기에서처음로그인하면_로컬과서버위시가합쳐진다() async throws {
        // Given: A 는 로그인해서 올려 두었고, B 에는 비회원으로 적은 위시가 있다
        _ = try deviceA.repository.addWish(Wish(id: "from-a", title: "A 위시")).get()
        _ = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        _ = try deviceB.repository.addWish(Wish(id: "from-b", title: "B 위시")).get()

        // When
        var progress: [Int] = []
        let outcome = await deviceB.engine.startSession(uid: "uid-1") { done, _ in progress.append(done) }

        // Then
        XCTAssertEqual(outcome, .merged)
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "from-a"))
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "from-b"))
        XCTAssertNotNil(server.documents[.wish]?["from-b"])
        XCTAssertEqual(progress.last, 1)
        await deviceA.engine.sync(trigger: .manual)
        XCTAssertNotNil(deviceA.repository.fetchWish(id: "from-b"))
    }

    // MARK: TC-31

    func test_GH93_TC31_다른계정위시가남은기기에서로그인하면_합치지않는다() async throws {
        // Given: uid-1 로 쓰다가 "남기기"로 로그아웃
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "1번 계정 위시")).get()
        _ = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        await deviceA.engine.endSession(unbindDevice: false, flushPending: true)
        let pushesBefore = server.pushCallCount

        // When
        let outcome = await deviceA.engine.startSession(uid: "uid-2") { _, _ in }

        // Then
        XCTAssertEqual(outcome, .accountMismatch)
        XCTAssertEqual(server.pushCallCount, pushesBefore)

        // 같은 계정으로 돌아오면 합친다 (S7')
        let sameAccount = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }
        XCTAssertEqual(sameAccount, .merged)
    }

    // MARK: TC-32

    func test_GH93_TC32_받은위시의알림은다시예약되고_삭제완료된위시알림은취소된다() async throws {
        // Given
        await signInBoth()
        let notification = SeepNotification(type: .targetDay, time: start)
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주", endDate: start.addingTimeInterval(86_400 * 10), notifications: [notification])).get()
        await deviceA.engine.sync(trigger: .manual)

        // When: 받으면 예약
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.notifications.reservedWishes.map(\.id), ["w1"])

        // When: A 가 지운 것을 받으면 취소
        deviceA.tick(60)
        deviceA.repository.deleteWish(id: "w1")
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.notifications.cancelledWishes.map(\.id), ["w1"])
        XCTAssertEqual(deviceB.notifications.reservedWishes.count, 1)
    }

    // MARK: TC-33

    func test_GH93_TC33_고정과내순서도_다른기기에반영된다() async throws {
        // Given
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "하나")).get()
        _ = try deviceA.repository.addWish(Wish(id: "w2", title: "둘")).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // When
        deviceA.tick(60)
        _ = try deviceA.repository.updatePin(wishId: "w2", isPinned: true).get()
        _ = try deviceA.repository.moveWish(wishId: "w1", orderedIds: ["w2", "w1"]).get()
        await deviceA.engine.sync(trigger: .manual)
        await deviceB.engine.sync(trigger: .manual)

        // Then
        let a1 = try XCTUnwrap(deviceA.repository.fetchWish(id: "w1"))
        let b1 = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        XCTAssertNotNil(deviceB.repository.fetchWish(id: "w2")?.pinnedAt)
        XCTAssertEqual(b1.manualOrder, a1.manualOrder)
    }

    // MARK: TC-34

    func test_GH93_TC34_더새앱이쓴문서는아는필드만적용하고_다시올려도모르는필드를지우지않는다() async throws {
        // Given: 더 새 앱이 모르는 필드와 함께 쓴 위시
        await signInBoth()
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        await deviceA.engine.sync(trigger: .manual)
        var fields = try XCTUnwrap(server.documents[.wish]?["w1"]?.fields)
        fields["futureField"] = .text("v99 에서 추가")
        fields["title"] = .text("새 앱이 고침")
        fields["updatedAt"] = .double(900_000_000)
        server.put(.wish, id: "w1", fields: fields)

        // When
        await deviceB.engine.sync(trigger: .manual)

        // Then: 아는 필드는 적용
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.title, "새 앱이 고침")

        // When: B 가 고쳐서 다시 올린다
        deviceB.clock = Date(timeIntervalSinceReferenceDate: 900_000_100)
        var wish = try XCTUnwrap(deviceB.repository.fetchWish(id: "w1"))
        wish.memo = "B 메모"
        _ = try deviceB.repository.updateWish(wish).get()
        await deviceB.engine.sync(trigger: .localChange)

        // Then: 모르는 필드는 서버에 남는다
        XCTAssertEqual(server.documents[.wish]?["w1"]?.fields["futureField"], .text("v99 에서 추가"))
        XCTAssertEqual(server.documents[.wish]?["w1"]?.fields["memo"], .text("B 메모"))
    }

    // MARK: TC-35

    func test_GH93_TC35_한사이클마다_sync_push와sync_pull이1건씩_실패하면sync_error가1건간다() async throws {
        // Given
        await signInBoth()
        let before = deviceA.logManager.sentEvents.count

        // When
        await deviceA.engine.sync(trigger: .manual)

        // Then
        let events = deviceA.logManager.sentEvents.dropFirst(before)
        XCTAssertEqual(events.filter { $0.name == .syncPush }.count, 1)
        XCTAssertEqual(events.filter { $0.name == .syncPull }.count, 1)
        XCTAssertEqual(events.first { $0.name == .syncPush }?.extraParameters?[.trigger] as? String, "manual")

        // When: 실패
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()
        server.failPush = true
        let failedBefore = deviceA.logManager.sentEvents.count
        await deviceA.engine.sync(trigger: .manual)

        // Then
        let failedEvents = deviceA.logManager.sentEvents.dropFirst(failedBefore)
        XCTAssertEqual(failedEvents.filter { $0.name == .syncError }.count, 1)
        XCTAssertEqual(failedEvents.first?.extraParameters?[.errorType] as? String, "push")
    }

    // MARK: 로그인 전

    func test_GH93_TC23_로그인전에는_서버에붙지않고아웃박스를비운다() async throws {
        // Given
        _ = try deviceA.repository.addWish(Wish(id: "w1", title: "제주")).get()

        // When
        let report = await deviceA.engine.sync(trigger: .launch)

        // Then
        XCTAssertTrue(report.isSkipped)
        XCTAssertEqual(server.pushCallCount, 0)
        XCTAssertEqual(deviceA.store.pendingCount(), 0)
    }
}
