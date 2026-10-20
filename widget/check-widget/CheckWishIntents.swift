import AppIntents
import UserNotifications
import WidgetKit

/// 체크 원: 다음 단계를 체크하거나(남은 단계 2개 이상) 위시를 완료한다 (GH-48 R-3)
@available(iOSApplicationExtension 17.0, *)
struct CheckWishIntent: AppIntent {
    static var title: LocalizedStringResource = "위시 체크하기"
    static var isDiscoverable: Bool = false

    @Parameter(title: "위시 ID")
    var wishId: String

    init() {}

    init(wishId: String) {
        self.wishId = wishId
    }

    func perform() async throws -> some IntentResult {
        let repository = WidgetCheckRepositoryImpl()
        guard let wish = repository.fetchWish(id: wishId), !wish.isSuccess else { return .result() }

        switch WidgetCheckAction.make(wish: wish) {
        case .checkStep(let stepId):
            _ = repository.checkStep(wishId: wishId, stepId: stepId)
        case .finishWish(let lastStepId):
            if case .success(let finishedWish) = repository.finishWish(wishId: wishId, lastStepId: lastStepId) {
                // 위젯 프로세스에서도 앱의 대기 중 알림을 지울 수 있다. 앱도 다음 활성화 때 한 번 더 지운다 (R-13, R-7)
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: finishedWish.notifications.map(\.id))
            }
        }
        // 남은 수·D-day 목록 등 다른 싶 위젯도 같이 갱신한다 (R-5)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// 완료 모양인 줄의 체크 원: 위젯에서 한 완료를 취소한다. 단계 체크는 되돌리지 않는다 (GH-48 R-4)
@available(iOSApplicationExtension 17.0, *)
struct UncheckWishIntent: AppIntent {
    static var title: LocalizedStringResource = "위시 완료 취소하기"
    static var isDiscoverable: Bool = false

    @Parameter(title: "위시 ID")
    var wishId: String

    init() {}

    init(wishId: String) {
        self.wishId = wishId
    }

    func perform() async throws -> some IntentResult {
        let repository = WidgetCheckRepositoryImpl()
        guard let wish = repository.fetchWish(id: wishId), wish.isSuccess else { return .result() }

        _ = repository.unfinishWish(wishId: wishId)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
