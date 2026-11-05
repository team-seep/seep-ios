import Foundation

/// 동기화를 부르는 계기. `localChange`는 올리기만 한다(받기는 읽기 비용이 들어 실행·포그라운드·수동일 때만)
enum SyncTrigger: String {
    case launch
    case foreground
    case localChange = "local_change"
    case manual
}

enum SyncSessionOutcome: Equatable {
    case merged
    /// 이 기기 로컬 데이터가 다른 계정 것이다. 합치지 않는다 (설계 §6.3 S7)
    case accountMismatch
    case failed
}

struct SyncReport: Equatable {
    var pushed = 0
    var pulled = 0
    var changedWishIds: Set<String> = []
    var photosUploaded = 0
    var photosDownloaded = 0
    /// 오래 안 켠 기기라 증분 대신 전체를 받았다 (R-45)
    var isFullPull = false
    /// 물리 삭제한 로컬 줄 (R-44, R-45)
    var purged = 0
    /// 실패한 단계(push·pull). nil 이면 성공 또는 건너뜀
    var failedStage: String?
    var isSkipped = false
}

struct SyncStatus: Equatable {
    var isSignedIn: Bool
    var lastSyncedAt: Date?
    var pendingCount: Int
}

/// 로그인한 사용자의 위시를 서버와 맞춘다 (GH-93, 설계 §6). 화면·위젯은 지금처럼 로컬 DB 만 읽고 쓰고, 이 엔진이 뒤에서 따라간다.
/// 한 번에 하나씩 돈다(actor)
protocol SyncEngineProtocol: AnyObject, Sendable {
    func status() async -> SyncStatus
    /// 로그인 직후. 로컬 전체를 올리고 서버 전체를 받아 합친다(합집합). `progress`는 (올린 수, 전체)
    func startSession(uid: String, progress: @escaping @Sendable (Int, Int) -> Void) async -> SyncSessionOutcome
    /// 다른 계정 확인에서 "이 기기 싶 지우고 받기": 호출한 쪽이 로컬을 지운 뒤 부른다
    func forgetBoundAccount() async
    /// 로그아웃·계정 삭제. Firebase 로그아웃 **전에** 부른다(남은 변경을 올리려면 로그인이 필요하다).
    /// `unbindDevice`면 이 기기 로컬 데이터가 어느 계정에도 묶이지 않는다(지우기·계정 삭제). `flushPending`이면 남은 변경을 한 번 올려 본다
    func endSession(unbindDevice: Bool, flushPending: Bool) async
    @discardableResult
    func sync(trigger: SyncTrigger) async -> SyncReport
}

actor SyncEngine: SyncEngineProtocol {
    struct Dependency {
        let store: SyncStore
        let remote: RemoteWishStore
        let photos: RemotePhotoStore
        let photoStorage: WishPhotoStorage
        /// 내려받은 사진을 화면이 다시 그리게 한다(DB 는 그대로라 관찰로는 알 수 없다)
        let photosDidDownload: () -> Void
        /// Remote Config `sync_enabled` 킬 스위치 (R-30)
        let isEnabled: () -> Bool
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol
        let reloadWidgets: () -> Void
        let logManager: LogManagerProtocol
        let now: () -> Date
    }

    private enum StateKey {
        /// 처음 로그인 업로드가 끝나지 않았다. 다음 동기화가 아웃박스 대신 전체를 올린다
        static let needsFullUpload = "needsFullUpload"
    }

    private static let pushBatch = 450
    /// 한 번에 올리고 받는 사진 수. 처음 로그인처럼 많으면 다음 동기화로 이어 간다
    private static let photoBatch = 20

    private let dependency: Dependency
    private var store: SyncStore { dependency.store }

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    func status() async -> SyncStatus {
        SyncStatus(
            isSignedIn: store.value(SyncStore.StateKey.uid) != nil,
            lastSyncedAt: store.value(SyncStore.StateKey.lastSyncedAt).flatMap(Double.init).map(Date.init(timeIntervalSinceReferenceDate:)),
            pendingCount: store.pendingCount()
        )
    }

    func startSession(uid: String, progress: @escaping @Sendable (Int, Int) -> Void) async -> SyncSessionOutcome {
        if let bound = store.value(SyncStore.StateKey.boundUid), bound != uid {
            return .accountMismatch
        }
        store.setValue(uid, for: SyncStore.StateKey.uid)
        store.setValue("1", for: StateKey.needsFullUpload)
        store.clearCursors()
        do {
            try await uploadAll(uid: uid, progress: progress)
            store.setValue(uid, for: SyncStore.StateKey.boundUid)
            var report = SyncReport()
            await uploadPhotos(uid: uid, into: &report)
            try await pullAll(uid: uid, into: &report)
            await downloadMissingPhotos(uid: uid, into: &report)
            finish(report, trigger: .manual)
            return .merged
        } catch {
            sendErrorLog(stage: "sign_in")
            return .failed
        }
    }

    func forgetBoundAccount() async {
        store.setValue(nil, for: SyncStore.StateKey.boundUid)
    }

    func endSession(unbindDevice: Bool, flushPending: Bool) async {
        if flushPending, let uid = store.value(SyncStore.StateKey.uid) {
            // 아직 못 올린 변경을 한 번은 올려 본다. 실패해도 로그아웃은 막지 않는다
            var report = SyncReport()
            try? await push(uid: uid, into: &report)
        }
        store.setValue(nil, for: SyncStore.StateKey.uid)
        store.setValue(nil, for: StateKey.needsFullUpload)
        store.clearCursors()
        store.clearOutbox()
        store.clearPhotoOutbox()
        if unbindDevice {
            store.setValue(nil, for: SyncStore.StateKey.boundUid)
        }
    }

    @discardableResult
    func sync(trigger: SyncTrigger) async -> SyncReport {
        guard let uid = store.value(SyncStore.StateKey.uid) else {
            // 로그인 전에도 트리거는 쌓인다. 처음 로그인하면 전체를 올리므로 비워 둔다 (설계 §5)
            store.clearOutbox()
            store.clearPhotoOutbox()
            // 어느 계정에도 묶인 적 없는 기기는 삭제 표시를 서버에 알릴 일이 없다. 묶인 채 로그아웃한 기기는
            // 다시 로그인할 때 삭제 표시를 올려야 해서 남긴다
            if store.value(SyncStore.StateKey.boundUid) == nil {
                purgeTombstones()
            }
            return SyncReport(isSkipped: true)
        }
        guard dependency.isEnabled() else { return SyncReport(isSkipped: true) }
        // 로컬 쓰기 감지는 엔진 자신의 쓰기(syncState 등)에도 불린다. 올릴 것이 없으면 아무것도 하지 않는다
        if trigger == .localChange, store.pendingCount() == 0, store.pendingPhotoCount() == 0, store.value(StateKey.needsFullUpload) == nil {
            return SyncReport(isSkipped: true)
        }

        var report = SyncReport()
        do {
            if store.value(StateKey.needsFullUpload) != nil {
                try await uploadAll(uid: uid, progress: { _, _ in })
                store.setValue(uid, for: SyncStore.StateKey.boundUid)
                await uploadPhotos(uid: uid, into: &report)
            } else {
                try await push(uid: uid, into: &report)
            }
        } catch {
            report.failedStage = "push"
            sendErrorLog(stage: "push")
            return report
        }
        if trigger == .localChange {
            logPush(report, trigger: trigger)
            return report
        }
        report.isFullPull = needsFullPull()
        if report.isFullPull {
            store.clearCursors()
        }
        do {
            try await pullAll(uid: uid, into: &report, reconcile: report.isFullPull)
        } catch {
            report.failedStage = "pull"
            logPush(report, trigger: trigger)
            sendErrorLog(stage: "pull")
            return report
        }
        await downloadMissingPhotos(uid: uid, into: &report)
        report.purged += purgeTombstones()
        finish(report, trigger: trigger)
        return report
    }

    // MARK: - Private

    private func metadata(_ uid: String) -> SyncMetadata {
        SyncMetadata(
            ownerUid: uid,
            schemaVersion: store.schemaVersion,
            purgeAt: dependency.now().addingTimeInterval(TombstonePolicy.retention)
        )
    }

    /// 마지막으로 받은 지 오래되면 그사이 서버에서 TTL 로 지워진 삭제 표시를 증분으로는 받을 수 없다 (R-45)
    private func needsFullPull() -> Bool {
        guard let last = store.value(SyncStore.StateKey.lastSyncedAt).flatMap(Double.init) else { return false }
        return dependency.now().timeIntervalSinceReferenceDate - last > TombstonePolicy.fullPullAfter
    }

    /// 삭제 표시 후 90일 지났고 이미 올린 로컬 줄을 지운다 (R-44)
    @discardableResult
    private func purgeTombstones() -> Int {
        store.purgeTombstones(deletedBefore: dependency.now().addingTimeInterval(-TombstonePolicy.retention))
    }

    private func uploadAll(uid: String, progress: @escaping @Sendable (Int, Int) -> Void) async throws {
        store.clearOutbox()
        store.enqueueAllPhotos()
        let documents = store.allDocuments()
        progress(0, documents.count)
        var done = 0
        for start in stride(from: 0, to: documents.count, by: Self.pushBatch) {
            let chunk = Array(documents[start..<min(start + Self.pushBatch, documents.count)])
            try await dependency.remote.push(chunk, metadata: metadata(uid))
            done += chunk.count
            progress(done, documents.count)
        }
        store.setValue(nil, for: StateKey.needsFullUpload)
    }

    /// 사진을 문서보다 먼저 올린다. 다른 기기가 사진 이름이 든 위시를 받았을 때 파일이 이미 서버에 있게 한다 (설계 §7)
    private func push(uid: String, into report: inout SyncReport) async throws {
        await uploadPhotos(uid: uid, into: &report)
        while let pending = store.pendingDocuments(limit: Self.pushBatch) {
            if !pending.documents.isEmpty {
                try await dependency.remote.push(pending.documents, metadata: metadata(uid))
            }
            store.removeOutbox(upTo: pending.lastSeq)
            report.pushed += pending.documents.count
        }
    }

    /// 컬렉션을 모두 받은 뒤 한 트랜잭션에 적용하고, 알림 다시 예약은 위시마다 한 번만 한다.
    /// `reconcile`(전체 다시 받기)이면 서버에 없는 로컬 줄을 지운다
    private func pullAll(uid: String, into report: inout SyncReport, reconcile: Bool = false) async throws {
        var received: [SyncCollection: [SyncDocument]] = [:]
        for collection in SyncCollection.allCases {
            received[collection] = try await dependency.remote.pull(collection, uid: uid, after: store.cursor(collection))
        }
        let documents = SyncCollection.allCases.flatMap { received[$0] ?? [] }
        // 받기가 모두 성공한 뒤에만 정리한다. 일부만 받고 정리하면 못 받은 줄까지 지운다
        if reconcile {
            removeRowsMissingFromServer(received: received, into: &report)
        }
        guard !documents.isEmpty else { return }
        report.pulled += documents.count

        let before = Set(documents.compactMap(\.wishId)).compactMap(dependency.wishRepository.fetchWish(id:))
        let result = store.apply(documents)
        report.changedWishIds.formUnion(result.changedWishIds)
        rescheduleNotifications(before: before, changed: result.changedWishIds)
        for (collection, page) in received where !page.isEmpty {
            let deferred = result.deferred.filter { $0.collection == collection }
            store.setCursor(Self.cursor(after: page, deferred: deferred) ?? store.cursor(collection), for: collection)
        }
    }

    /// 서버에서 TTL 로 지워진 위시는 이 기기에서도 지운다. 살아 있던 위시면 알림·사진도 정리한다
    private func removeRowsMissingFromServer(received: [SyncCollection: [SyncDocument]], into report: inout SyncReport) {
        let missing = store.rowsMissing(fromServer: received.mapValues { Set($0.map(\.id)) })
        guard !missing.isEmpty else { return }
        let wishIds = missing[.wish] ?? []
        let alive = wishIds.compactMap(dependency.wishRepository.fetchWish(id:))
        store.deleteRows(missing)
        for wish in alive {
            dependency.notificationManager.cancelNotifications(wish: wish)
        }
        wishIds.forEach(dependency.photoStorage.deletePhotos(wishId:))
        report.purged += missing.values.reduce(0) { $0 + $1.count }
        report.changedWishIds.formUnion(alive.map(\.id))
    }

    /// 업로드 큐의 사진을 올린다. 실패한 사진은 큐에 남겨 다음 동기화에서 다시 올리고, 문서 동기화는 막지 않는다
    private func uploadPhotos(uid: String, into report: inout SyncReport) async {
        var failed = false
        for fileName in store.pendingPhotoFileNames(limit: Self.photoBatch) {
            // 파일이 없으면(올리기 전에 사진을 바꾸거나 지움) 올릴 것이 없다
            guard let fileURL = dependency.photoStorage.photoURL(fileName: fileName) else {
                store.removePendingPhoto(fileName)
                continue
            }
            do {
                try await dependency.photos.upload(fileURL: fileURL, fileName: fileName, uid: uid)
                store.removePendingPhoto(fileName)
                report.photosUploaded += 1
            } catch {
                failed = true
            }
        }
        if failed { sendErrorLog(stage: "photo_upload") }
    }

    /// 이름만 있고 이 기기에 파일이 없는 사진을 받는다 (R-41). 아직 안 올라왔으면(notFound) 다음 동기화에서 다시 본다
    private func downloadMissingPhotos(uid: String, into report: inout SyncReport) async {
        let missing = store.referencedPhotoFileNames()
            .filter { dependency.photoStorage.photoURL(fileName: $0) == nil }
            .prefix(Self.photoBatch)
        var failed = false
        for fileName in missing {
            do {
                let data = try await dependency.photos.download(fileName: fileName, uid: uid)
                try dependency.photoStorage.importPhoto(data: data, fileName: fileName)
                report.photosDownloaded += 1
            } catch RemotePhotoError.notFound {
                continue
            } catch {
                failed = true
            }
        }
        if failed { sendErrorLog(stage: "photo_download") }
        if report.photosDownloaded > 0 { dependency.photosDidDownload() }
    }

    /// 부모가 없어 미룬 문서가 있으면 그 앞까지만 커서를 올린다 (설계 §6.2)
    private static func cursor(after documents: [SyncDocument], deferred: [SyncDocument]) -> RemoteTimestamp? {
        let timestamps = documents.compactMap(\.serverUpdatedAt)
        guard let firstDeferred = deferred.compactMap(\.serverUpdatedAt).min() else { return timestamps.max() }
        return timestamps.filter { $0 < firstDeferred }.max()
    }

    /// 다른 기기에서 바꾼 D-day 알림을 이 기기에도 맞춘다. 알림 id 는 `wishNotification.id`라 다시 예약하면 덮어쓴다 (설계 §6.1)
    private func rescheduleNotifications(before: [Wish], changed: Set<String>) {
        for wish in before where changed.contains(wish.id) {
            dependency.notificationManager.cancelNotifications(wish: wish)
            // 다른 기기에서 지운 위시면 이 기기에 남은 사진 파일도 지운다 (R-42)
            if dependency.wishRepository.fetchWish(id: wish.id) == nil {
                dependency.photoStorage.deletePhotos(wishId: wish.id)
            }
        }
        for id in changed {
            guard let wish = dependency.wishRepository.fetchWish(id: id), !wish.isSuccess else { continue }
            dependency.notificationManager.reserveNotifications(wish: wish)
        }
    }

    private func finish(_ report: SyncReport, trigger: SyncTrigger) {
        store.setValue(String(dependency.now().timeIntervalSinceReferenceDate), for: SyncStore.StateKey.lastSyncedAt)
        if !report.changedWishIds.isEmpty {
            dependency.reloadWidgets()
        }
        logPush(report, trigger: trigger)
        dependency.logManager.sendEvent(event: CustomEvent(
            screen: .sync,
            name: .syncPull,
            extraParameters: [
                .count: report.pulled,
                .photoCount: report.photosDownloaded,
                .purgeCount: report.purged,
                // GA 는 불 값을 따로 다루지 않아 0·1 로 보낸다
                .isFullPull: report.isFullPull ? 1 : 0,
                .trigger: trigger.rawValue
            ]
        ))
    }

    private func logPush(_ report: SyncReport, trigger: SyncTrigger) {
        dependency.logManager.sendEvent(event: CustomEvent(
            screen: .sync,
            name: .syncPush,
            extraParameters: [.count: report.pushed, .photoCount: report.photosUploaded, .trigger: trigger.rawValue]
        ))
    }

    private func sendErrorLog(stage: String) {
        dependency.logManager.sendEvent(event: CustomEvent(screen: .sync, name: .syncError, extraParameters: [.errorType: stage]))
    }
}

extension SyncEngine {
    /// 앱 전체가 같이 쓰는 엔진. Firestore 는 처음 push·pull 할 때 연다(비회원은 서버에 붙지 않는다)
    static let shared = SyncEngine(dependency: Dependency(
        store: SyncStore(),
        remote: FirestoreRemoteWishStore(),
        photos: FirebaseRemotePhotoStore(),
        photoStorage: WishPhotoStorageImpl.shared,
        photosDidDownload: { NotificationCenter.default.post(name: .wishPhotosDidDownload, object: nil) },
        isEnabled: { RemoteConfigRepositoryImpl().fetchSyncEnabled() },
        wishRepository: WishRepositoryImpl(),
        notificationManager: NotificationManager.shared,
        reloadWidgets: WidgetReloader.reloadAll,
        logManager: LogManager.shared,
        now: Date.init
    ))
}

extension Notification.Name {
    /// 동기화가 다른 기기의 사진 파일을 받았다. 화면이 사진을 다시 읽는다 (GH-93 R-41)
    static let wishPhotosDidDownload = Notification.Name("wishPhotosDidDownload")
}
