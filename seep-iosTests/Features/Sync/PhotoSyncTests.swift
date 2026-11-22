import XCTest

@testable import seep_ios

/// 사진 동기화 (GH-93 3단계 R-40·R-41, 설계 §7). 기기 두 대 = 메모리 DB 두 개 + 메모리 서버·Storage 하나
final class PhotoSyncTests: XCTestCase {
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
        _ = await deviceA.engine.startSession(uid: uid) { _, _ in }
        _ = await deviceB.engine.startSession(uid: uid) { _, _ in }
    }

    private func errorTypes(_ device: SyncTestDevice) -> [String] {
        device.logManager.sentEvents
            .filter { $0.name == .syncError }
            .compactMap { $0.extraParameters?[.errorType] as? String }
    }

    // MARK: TC-37

    func test_GH93_TC37_사진을붙이면_업로드큐에들어가고_올리면빠진다() async throws {
        // Given
        await signInBoth()
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")
        XCTAssertEqual(deviceA.store.pendingPhotoFileNames(limit: 10), ["w1-a.jpg"])

        // When
        let report = await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertEqual(report.photosUploaded, 1)
        XCTAssertEqual(deviceA.store.pendingPhotoCount(), 0)
        XCTAssertNotNil(photoServer.files["wishPhotos/uid-1/w1-a.jpg"])
        XCTAssertNotNil(server.documents[.wish]?["w1"])
        let push = deviceA.logManager.sentEvents.last { $0.name == .syncPush }
        XCTAssertEqual(push?.extraParameters?[.photoCount] as? Int, 1)
    }

    func test_GH93_TC37_사진업로드가실패하면_큐에남고_문서동기화는계속된다() async throws {
        // Given
        await signInBoth()
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")
        photoServer.failUpload = true

        // When
        let failed = await deviceA.engine.sync(trigger: .localChange)

        // Then: 문서는 올라가고 사진은 다음에 다시
        XCTAssertNil(failed.failedStage)
        XCTAssertNotNil(server.documents[.wish]?["w1"])
        XCTAssertEqual(deviceA.store.pendingPhotoFileNames(limit: 10), ["w1-a.jpg"])
        XCTAssertEqual(errorTypes(deviceA), ["photo_upload"])

        // When: 다음 동기화(위시를 고치지 않아도 사진만으로 돈다)
        photoServer.failUpload = false
        let retried = await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertEqual(retried.photosUploaded, 1)
        XCTAssertEqual(deviceA.store.pendingPhotoCount(), 0)
    }

    func test_GH93_TC37_올리기전에사진을바꾸면_없는옛파일은올리지않는다() async throws {
        // Given
        await signInBoth()
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-old.jpg")
        deviceA.photoStorage.deletePhoto(fileName: "w1-old.jpg")
        var wish = try XCTUnwrap(deviceA.repository.fetchWish(id: "w1"))
        deviceA.photoStorage.existingFileNames.insert("w1-new.jpg")
        wish.photoFileName = "w1-new.jpg"
        _ = try deviceA.repository.updateWish(wish).get()

        // When
        await deviceA.engine.sync(trigger: .localChange)

        // Then
        XCTAssertEqual(photoServer.uploadCallCount, 1)
        XCTAssertNotNil(photoServer.files["wishPhotos/uid-1/w1-new.jpg"])
        XCTAssertEqual(deviceA.store.pendingPhotoCount(), 0)
    }

    // MARK: TC-38

    func test_GH93_TC38_로컬에없는사진은_내려받아저장하고_화면을다시그린다() async throws {
        // Given
        await signInBoth()
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")
        await deviceA.engine.sync(trigger: .manual)

        // When
        let report = await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(deviceB.repository.fetchWish(id: "w1")?.photoFileName, "w1-a.jpg")
        XCTAssertEqual(report.photosDownloaded, 1)
        XCTAssertEqual(deviceB.photoStorage.importedFileNames, ["w1-a.jpg"])
        XCTAssertNotNil(deviceB.photoStorage.photoURL(fileName: "w1-a.jpg"))
        XCTAssertEqual(deviceB.photosDidDownloadCount, 1)
        // 받은 사진은 B 가 다시 올리지 않는다
        XCTAssertEqual(deviceB.store.pendingPhotoCount(), 0)

        // When: 다시 동기화해도 이미 있는 사진은 받지 않는다
        await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(photoServer.downloadRequests, ["w1-a.jpg"])
    }

    func test_GH93_TC38_사진이아직서버에없으면_다음동기화에서다시받는다() async throws {
        // Given: A 의 사진 업로드만 실패해 위시 문서가 먼저 올라갔다
        await signInBoth()
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")
        photoServer.failUpload = true
        await deviceA.engine.sync(trigger: .manual)

        // When
        let first = await deviceB.engine.sync(trigger: .manual)

        // Then: 오류로 치지 않는다
        XCTAssertEqual(first.photosDownloaded, 0)
        XCTAssertTrue(errorTypes(deviceB).isEmpty)
        XCTAssertEqual(deviceB.photosDidDownloadCount, 0)

        // When: A 가 사진을 올린 뒤 B 가 다시 동기화
        photoServer.failUpload = false
        await deviceA.engine.sync(trigger: .localChange)
        let second = await deviceB.engine.sync(trigger: .manual)

        // Then
        XCTAssertEqual(second.photosDownloaded, 1)
        XCTAssertNotNil(deviceB.photoStorage.photoURL(fileName: "w1-a.jpg"))
    }

    func test_GH93_TC38_올리기만하는동기화는_사진을받지않는다() async throws {
        // Given
        await signInBoth()
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")
        await deviceA.engine.sync(trigger: .manual)
        _ = try deviceB.repository.addWish(Wish(id: "w2", title: "B 위시")).get()

        // When
        await deviceB.engine.sync(trigger: .localChange)

        // Then
        XCTAssertTrue(photoServer.downloadRequests.isEmpty)
    }

    // MARK: TC-46

    func test_GH93_TC46_처음로그인하면_이미있던사진도올라간다() async throws {
        // Given: 비회원일 때 붙인 사진. 비회원 큐는 쌓이지 않는다
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")
        await deviceA.engine.sync(trigger: .localChange)
        XCTAssertEqual(deviceA.store.pendingPhotoCount(), 0)
        XCTAssertTrue(photoServer.files.isEmpty)

        // When
        let outcome = await deviceA.engine.startSession(uid: "uid-1") { _, _ in }

        // Then
        XCTAssertEqual(outcome, .merged)
        XCTAssertNotNil(photoServer.files["wishPhotos/uid-1/w1-a.jpg"])
        XCTAssertEqual(deviceA.store.pendingPhotoCount(), 0)
    }

    func test_GH93_TC46_로그아웃하면_사진업로드큐를비운다() async throws {
        // Given
        await signInBoth()
        photoServer.failUpload = true
        try deviceA.addWishWithPhoto(id: "w1", fileName: "w1-a.jpg")

        // When
        await deviceA.engine.endSession(unbindDevice: false, flushPending: true)

        // Then
        XCTAssertEqual(deviceA.store.pendingPhotoCount(), 0)
    }
}
