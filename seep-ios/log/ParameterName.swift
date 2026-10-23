import Foundation

struct ParameterName: RawRepresentable, Hashable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ParameterName {
    static let screen = ParameterName(rawValue: "screen")
    static let objectId = ParameterName(rawValue: "object_id")
    static let objectType = ParameterName(rawValue: "object_type")
    static let type = ParameterName(rawValue: "type")
    static let value = ParameterName(rawValue: "value")
    static let count = ParameterName(rawValue: "count")
    static let category = ParameterName(rawValue: "category")
    static let wishId = ParameterName(rawValue: "wish_id")
    static let isDone = ParameterName(rawValue: "is_done")
    static let hasTargetAmount = ParameterName(rawValue: "has_target_amount")
    static let year = ParameterName(rawValue: "year")
    static let badgeId = ParameterName(rawValue: "badge_id")
    /// 설정 탭 잠금 줄을 눌렀을 때 잠금이 켜져 있었는지 (GH-64)
    static let enabled = ParameterName(rawValue: "enabled")
}
