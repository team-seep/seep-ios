@testable import seep_ios

/// 근처 알림 스케줄러 목 (GH-126). 권한 결과·한도를 정하고 예약·취소 호출을 기록한다
final class MockNearbyAlertScheduler: NearbyAlertSchedulerProtocol {
    var isAtLimitResult = false
    private(set) var isAtLimitCalledIds: [String] = []
    var requestAuthorizationResult = true
    private(set) var requestAuthorizationCallCount = 0
    private(set) var scheduledWishes: [Wish] = []
    private(set) var cancelledWishIds: [String] = []
    private(set) var rescheduleMissingCallCount = 0

    func isAtLimit(excluding wishId: String) -> Bool {
        isAtLimitCalledIds.append(wishId)
        return isAtLimitResult
    }

    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return requestAuthorizationResult
    }

    func schedule(wish: Wish) async {
        scheduledWishes.append(wish)
    }

    func cancel(wishId: String) {
        cancelledWishIds.append(wishId)
    }

    func rescheduleMissing() async {
        rescheduleMissingCallCount += 1
    }
}
