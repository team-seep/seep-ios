import Foundation

/// 체크 위젯(GH-48)이 앱에 남기는 기록. 위젯 인텐트와 앱이 App Group UserDefaults 로 주고받는다.
/// - `widgetFinishedWishIds`: 위젯에서 완료해 앱이 아직 처리(알림 취소·소감 시트)하지 않은 위시 id. 최근 것이 앞 (R-7)
/// - `widgetDoneWishIds`: 위젯에서 완료해 그날 자정까지 완료 모양으로 남길 줄. id → 완료 시각 (R-4)
/// - `widgetActionLogs`: 위젯은 GA 를 못 보내 실행 기록만 쌓고 앱이 보낸다 (트래킹 이벤트)
/// - `widgetMutatedAt`: 위젯이 마지막으로 DB 에 쓴 시각. 앱이 홈을 다시 읽을지 정한다 (R-8)
final class WidgetCheckStore {
    enum Action: String, Equatable {
        case checkStep = "check_step"
        case finishWish = "finish_wish"
        case unfinishWish = "unfinish_wish"
    }

    struct ActionLog: Equatable {
        let action: Action
        let at: Date
    }

    static let shared = WidgetCheckStore()

    private enum Key {
        static let finishedWishIds = "widgetFinishedWishIds"
        static let doneWishIds = "widgetDoneWishIds"
        static let actionLogs = "widgetActionLogs"
        static let mutatedAt = "widgetMutatedAt"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults? = UserDefaults(suiteName: AppDatabase.appGroupIdentifier)) {
        self.userDefaults = userDefaults ?? .standard
    }

    var finishedWishIds: [String] {
        get { userDefaults.stringArray(forKey: Key.finishedWishIds) ?? [] }
        set { userDefaults.set(newValue, forKey: Key.finishedWishIds) }
    }

    var doneWishDates: [String: Date] {
        get {
            let raw = userDefaults.dictionary(forKey: Key.doneWishIds) as? [String: Double] ?? [:]
            return raw.mapValues { Date(timeIntervalSince1970: $0) }
        }
        set { userDefaults.set(newValue.mapValues(\.timeIntervalSince1970), forKey: Key.doneWishIds) }
    }

    var actionLogs: [ActionLog] {
        get {
            let raw = userDefaults.array(forKey: Key.actionLogs) as? [[String: Any]] ?? []
            return raw.compactMap { item in
                guard let action = (item["action"] as? String).flatMap(Action.init(rawValue:)),
                      let at = item["at"] as? Double else { return nil }
                return ActionLog(action: action, at: Date(timeIntervalSince1970: at))
            }
        }
        set {
            let raw: [[String: Any]] = newValue.map { ["action": $0.action.rawValue, "at": $0.at.timeIntervalSince1970] }
            userDefaults.set(raw, forKey: Key.actionLogs)
        }
    }

    var mutatedAt: Date? {
        get {
            let value = userDefaults.double(forKey: Key.mutatedAt)
            return value > 0 ? Date(timeIntervalSince1970: value) : nil
        }
        set { userDefaults.set(newValue?.timeIntervalSince1970, forKey: Key.mutatedAt) }
    }

    /// 오늘(`now` 기준) 위젯에서 완료한 위시 id. 어제 이전 기록은 지운다
    func doneWishIds(now: Date, calendar: Calendar = .current) -> Set<String> {
        let today = doneWishDates.filter { calendar.isDate($0.value, inSameDayAs: now) }
        if today.count != doneWishDates.count {
            doneWishDates = today
        }
        return Set(today.keys)
    }

    func recordStepCheck(at date: Date) {
        append(.checkStep, at: date)
    }

    func recordFinish(wishId: String, at date: Date) {
        finishedWishIds = [wishId] + finishedWishIds.filter { $0 != wishId }
        var doneDates = doneWishDates
        doneDates[wishId] = date
        doneWishDates = doneDates
        append(.finishWish, at: date)
    }

    func recordUnfinish(wishId: String, at date: Date) {
        finishedWishIds = finishedWishIds.filter { $0 != wishId }
        var doneDates = doneWishDates
        doneDates[wishId] = nil
        doneWishDates = doneDates
        append(.unfinishWish, at: date)
    }

    private func append(_ action: Action, at date: Date) {
        actionLogs += [ActionLog(action: action, at: date)]
        mutatedAt = date
    }
}
