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
            try await pullAll(uid: uid, into: &report)
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
        if unbindDevice {
            store.setValue(nil, for: SyncStore.StateKey.boundUid)
        }
    }

    @discardableResult
    func sync(trigger: SyncTrigger) async -> SyncReport {
        guard let uid = store.value(SyncStore.StateKey.uid) else {
            // 로그인 전에도 트리거는 쌓인다. 처음 로그인하면 전체를 올리므로 비워 둔다 (설계 §5)
            store.clearOutbox()
            return SyncReport(isSkipped: true)
        }
        guard dependency.isEnabled() else { return SyncReport(isSkipped: true) }
        // 로컬 쓰기 감지는 엔진 자신의 쓰기(syncState 등)에도 불린다. 올릴 것이 없으면 아무것도 하지 않는다
        if trigger == .localChange, store.pendingCount() == 0, store.value(StateKey.needsFullUpload) == nil {
            return SyncReport(isSkipped: true)
        }

        var report = SyncReport()
        do {
            if store.value(StateKey.needsFullUpload) != nil {
                try await uploadAll(uid: uid, progress: { _, _ in })
                store.setValue(uid, for: SyncStore.StateKey.boundUid)
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
        do {
            try await pullAll(uid: uid, into: &report)
        } catch {
            report.failedStage = "pull"
            logPush(report, trigger: trigger)
            sendErrorLog(stage: "pull")
            return report
        }
        finish(report, trigger: trigger)
        return report
    }

    // MARK: - Private

    private func metadata(_ uid: String) -> SyncMetadata {
        SyncMetadata(ownerUid: uid, schemaVersion: store.schemaVersion)
    }

    private func uploadAll(uid: String, progress: @escaping @Sendable (Int, Int) -> Void) async throws {
        store.clearOutbox()
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

    private func push(uid: String, into report: inout SyncReport) async throws {
        while let pending = store.pendingDocuments(limit: Self.pushBatch) {
            if !pending.documents.isEmpty {
                try await dependency.remote.push(pending.documents, metadata: metadata(uid))
            }
            store.removeOutbox(upTo: pending.lastSeq)
            report.pushed += pending.documents.count
        }
    }

    /// 컬렉션을 모두 받은 뒤 한 트랜잭션에 적용하고, 알림 다시 예약은 위시마다 한 번만 한다
    private func pullAll(uid: String, into report: inout SyncReport) async throws {
        var received: [SyncCollection: [SyncDocument]] = [:]
        for collection in SyncCollection.allCases {
            received[collection] = try await dependency.remote.pull(collection, uid: uid, after: store.cursor(collection))
        }
        let documents = SyncCollection.allCases.flatMap { received[$0] ?? [] }
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
            extraParameters: [.count: report.pulled, .trigger: trigger.rawValue]
        ))
    }

    private func logPush(_ report: SyncReport, trigger: SyncTrigger) {
        dependency.logManager.sendEvent(event: CustomEvent(
            screen: .sync,
            name: .syncPush,
            extraParameters: [.count: report.pushed, .trigger: trigger.rawValue]
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
        isEnabled: { RemoteConfigRepositoryImpl().fetchSyncEnabled() },
        wishRepository: WishRepositoryImpl(),
        notificationManager: NotificationManager.shared,
        reloadWidgets: WidgetReloader.reloadAll,
        logManager: LogManager.shared,
        now: Date.init
    ))
}
