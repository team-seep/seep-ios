import Foundation

/// 언제 동기화할지 정한다 (GH-93 R-38, 설계 §6.1). 실행·포그라운드는 올리고 받기, 로컬 쓰기는 2초 모았다가 올리기만.
/// 비회원이면 엔진이 아무것도 하지 않는다(서버에 붙지 않음)
@MainActor
final class SyncScheduler {
    static let shared = SyncScheduler()

    private static let debounce: Duration = .seconds(2)

    private let engine: SyncEngineProtocol
    private let wishRepository: WishRepository
    private var observation: WishChangeObservation?
    private var pendingLocalSync: Task<Void, Never>?

    init(engine: SyncEngineProtocol = SyncEngine.shared, wishRepository: WishRepository = WishRepositoryImpl()) {
        self.engine = engine
        self.wishRepository = wishRepository
    }

    func appDidBecomeActive(isLaunch: Bool) {
        startObservingIfNeeded()
        let engine = engine
        Task { await engine.sync(trigger: isLaunch ? .launch : .foreground) }
    }

    private func startObservingIfNeeded() {
        guard observation == nil else { return }
        // DB 쓰기 큐에서 불린다
        observation = wishRepository.observeChanges { [weak self] in
            Task { @MainActor in self?.scheduleLocalSync() }
        }
    }

    private func scheduleLocalSync() {
        pendingLocalSync?.cancel()
        let engine = engine
        pendingLocalSync = Task {
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            await engine.sync(trigger: .localChange)
        }
    }
}
