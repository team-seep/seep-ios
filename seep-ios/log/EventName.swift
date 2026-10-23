import Foundation

enum EventName: String {
    case click = "click"
    case impression = "impression"
    case savePhoto = "save_photo"
    /// Realm → GRDB 1회 이전 결과 (GH-79 R-22)
    case dbMigration = "db_migration"
}
