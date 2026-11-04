import Foundation

enum EventName: String {
    case click = "click"
    case impression = "impression"
    case savePhoto = "save_photo"
    /// Realm → GRDB 1회 이전 결과 (GH-79 R-22)
    case dbMigration = "db_migration"
    /// Apple 로그인(=가입) 성공 (GH-93 R-46)
    case accountSignIn = "account_sign_in"
    /// 로그아웃 (+type: keep·erase) (GH-93)
    case accountSignOut = "account_sign_out"
    /// 계정 삭제 완료 (GH-93)
    case accountDelete = "account_delete"
    /// 동기화 올리기 한 번 (+count, trigger) (GH-93)
    case syncPush = "sync_push"
    /// 동기화 받기 한 번 (+count, trigger) (GH-93)
    case syncPull = "sync_pull"
    /// 동기화 실패 (+error_type: sign_in·push·pull) (GH-93)
    case syncError = "sync_error"
}
