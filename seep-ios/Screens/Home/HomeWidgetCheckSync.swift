import Foundation

/// 체크 위젯(GH-48)이 App Group 에 남긴 기록을 앱에서 마무리한다.
/// 위젯 프로세스는 GA·소감 시트를 다룰 수 없어, 앱이 활성화될 때 홈이 이 타입으로 한 번에 처리한다.
struct HomeWidgetCheckSync {
    struct Result: Equatable {
        /// 위젯이 마지막으로 읽은 뒤에 Realm 을 바꿨으면 홈을 다시 읽는다 (R-8)
        let needsReload: Bool
        /// 소감을 물을 위시. 위젯에서 완료한 것 중 가장 최근 하나만 (R-7)
        let finishNoteWish: Wish?
    }

    let store: WidgetCheckStore
    let wishRepository: WishRepository
    let notificationManager: NotificationManagerProtocol
    let logManager: LogManagerProtocol

    func consume(lastSyncedAt: Date?) -> Result {
        sendActionLogs()

        let finishedWishIds = store.finishedWishIds
        if finishedWishIds.isNotEmpty {
            store.finishedWishIds = []
        }
        // 그사이 앱에서 완료를 취소했거나 지운 위시는 건너뛴다
        let finishedWishes = finishedWishIds
            .compactMap { wishRepository.fetchWish(id: $0) }
            .filter(\.isSuccess)
        finishedWishes.forEach { notificationManager.cancelNotifications(wish: $0) }

        let needsReload: Bool
        if let mutatedAt = store.mutatedAt {
            needsReload = lastSyncedAt.map { mutatedAt > $0 } ?? true
        } else {
            needsReload = false
        }

        return Result(
            needsReload: needsReload || finishedWishIds.isNotEmpty,
            finishNoteWish: finishedWishes.first { $0.finishNote.isEmpty }
        )
    }

    /// 전송 시각은 앱이 활성화된 시각이라 실제 체크 시각과 다를 수 있다 (트래킹 이벤트 한계)
    private func sendActionLogs() {
        let actionLogs = store.actionLogs
        guard actionLogs.isNotEmpty else { return }
        store.actionLogs = []
        actionLogs.forEach { logManager.sendEvent(event: $0.action.clickEvent) }
    }
}
