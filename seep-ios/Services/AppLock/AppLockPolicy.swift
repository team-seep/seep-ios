import Foundation

/// 백그라운드에서 돌아올 때 잠글지 판정한다 (GH-46 R-5, R-9)
enum AppLockPolicy {
    /// 이 시간 이상 백그라운드에 있다 돌아오면 잠근다
    static let backgroundThreshold: TimeInterval = 60

    static func shouldLock(lastBackgroundAt: Date?, now: Date, isEnabled: Bool) -> Bool {
        guard isEnabled else { return false }
        // 기록이 없으면 언제 떠났는지 모르니 잠근다
        guard let lastBackgroundAt else { return true }

        let elapsed = now.timeIntervalSince(lastBackgroundAt)
        // 기기 시간을 되돌려 경과 시간이 음수가 되면 잠금을 피해 가지 못하게 잠근다
        return elapsed < 0 || elapsed >= backgroundThreshold
    }
}
