import Foundation

@testable import seep_ios

// 동기화 테스트(SyncEngineTests·PhotoSyncTests·TombstoneCleanupTests)가 같이 쓰는 대역

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

/// 기기 한 대: 메모리 DB + 실제 저장소·엔진
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

    /// - Parameter makeNotificationManager: 엔진이 쓸 알림 관리자. nil 이면 `notifications`(목). 근처 알림 예약까지 보려면 실제 `NotificationManager`를 넘긴다 (GH-126 TC-13)
    init(
        server: FakeSyncServer,
        photoServer: FakePhotoServer = FakePhotoServer(),
        clock: Date,
        makeNotificationManager: ((WishRepository) -> NotificationManagerProtocol)? = nil
    ) throws {
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
            notificationManager: makeNotificationManager?(repository) ?? notifications,
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
