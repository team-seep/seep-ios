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
    /// 더하기 칩으로 꺼낸 칸 (GH-70)
    static let block = ParameterName(rawValue: "block")
    /// db_migration 결과: success / failure (GH-79 R-22)
    static let result = ParameterName(rawValue: "result")
    static let wishCount = ParameterName(rawValue: "wish_count")
    /// 겹치거나 비어 있어 새 id 를 붙인 레코드 수
    static let reassignedIdCount = ParameterName(rawValue: "reassigned_id_count")
    static let errorType = ParameterName(rawValue: "error_type")
    /// db_migration 이 돈 계기: launch / retry / reimport (GH-96)
    static let trigger = ParameterName(rawValue: "trigger")
    /// 원본 Realm 의 위시 수. wish_count 와 다르면 이전에서 빠진 것이 있다 (GH-96 R-15)
    static let realmWishCount = ParameterName(rawValue: "realm_wish_count")
    /// 재이전으로 새로 들어간 위시 수·하위 줄 수 (GH-96 R-7)
    static let restoredWishCount = ParameterName(rawValue: "restored_wish_count")
    static let restoredRowCount = ParameterName(rawValue: "restored_row_count")
}
