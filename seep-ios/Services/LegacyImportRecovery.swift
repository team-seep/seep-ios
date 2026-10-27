import Foundation
import WidgetKit

/// Realm → GRDB 1회 이전이 끝나지 못한 상태 (GH-96 R-9, R-12)
enum LegacyImportProblem: Equatable {
    /// 이전 중 오류. `errorType`은 `domain:code`
    case importFailed(errorType: String)
    /// DB 파일 자체를 열지 못했다. 실행 중에는 다시 열 수 없어 재실행을 안내한다
    case databaseUnavailable
}

/// 홈 이전 실패 카드가 쓰는 복구 통로 (GH-96 R-16)
protocol LegacyImportRecovering {
    func currentProblem() -> LegacyImportProblem?
    /// 1회 이전을 지금 다시 한다. 성공하면 불러온 위시 수
    func retry() async -> Result<Int, Error>
}

final class LegacyImportRecovery: LegacyImportRecovering {
    static let shared = LegacyImportRecovery()

    func currentProblem() -> LegacyImportProblem? {
        guard AppDatabase.shared != nil else { return .databaseUnavailable }
        guard let error = AppDatabase.sharedLegacyImportError else { return nil }
        return .importFailed(errorType: DatabaseMigrationFollowUp.errorType(error))
    }

    func retry() async -> Result<Int, Error> {
        // 파일 코디네이션·Realm 읽기가 메인 스레드를 막지 않게 밖에서 돈다
        await Task.detached(priority: .userInitiated) {
            do {
                let report = try AppDatabase.retrySharedLegacyImport()
                DatabaseMigrationFollowUp(dependency: .init(importError: nil)).run(trigger: .retry)
                WidgetCenter.shared.reloadAllTimelines()
                return .success(report?.wishCount ?? 0)
            } catch {
                DatabaseMigrationFollowUp(dependency: .init(importError: error)).run(trigger: .retry)
                return .failure(error)
            }
        }.value
    }
}
