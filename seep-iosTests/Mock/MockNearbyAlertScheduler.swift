@testable import seep_ios

/// 근처 알림 스케줄러 목 (GH-126). 권한 결과·한도를 정하고 예약·취소 호출을 기록한다
final class MockNearbyAlertScheduler: NearbyAlertSchedulerProtocol {
    var isAtLimitResult = false
    /// 차례로 돌려줄 한도 결과. 비면 `isAtLimitResult`
    var isAtLimitSequence: [Bool] = []
    private(set) var isAtLimitCalledIds: [String] = []
    var requestAuthorizationResult = true
    private(set) var requestAuthorizationCallCount = 0
    private(set) var scheduledWishes: [Wish] = []
    /// `schedule` 에 넘어온 취소 횟수 (nil = 지금 값)
    private(set) var scheduledCancelCounts: [Int?] = []
    var cancelCountResult = 0
    private(set) var cancelledWishIds: [String] = []
    private(set) var rescheduleMissingCallCount = 0

    func isAtLimit(excluding wishId: String) -> Bool {
        isAtLimitCalledIds.append(wishId)
        return isAtLimitSequence.isEmpty ? isAtLimitResult : isAtLimitSequence.removeFirst()
    }

    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return requestAuthorizationResult
    }

    func schedule(wish: Wish, cancelCount: Int?) async {
        scheduledWishes.append(wish)
        scheduledCancelCounts.append(cancelCount)
    }

    func cancelCount(wishId: String) -> Int {
        cancelCountResult
    }

    func cancel(wishId: String) {
        cancelledWishIds.append(wishId)
    }

    func rescheduleMissing() async {
        rescheduleMissingCallCount += 1
    }
}
