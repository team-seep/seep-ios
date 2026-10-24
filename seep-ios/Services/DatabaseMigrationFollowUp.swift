import Foundation

/// Realm → GRDB 1회 이전 뒤 앱이 할 일 (GH-79 R-22, R-23). 앱 실행 때 한 번 돈다.
/// 이전은 위젯이 먼저 했을 수도 있어서, 결과를 DB(`appMetadata`)에서 꺼내 처리하고 지운다.
struct DatabaseMigrationFollowUp {
    struct Dependency {
        let database: AppDatabase?
        /// 이번 실행에서 이전하다 난 오류. 있으면 실패 이벤트를 보낸다
        let importError: Error?
        let logManager: LogManagerProtocol
        let notificationManager: NotificationManagerProtocol

        init(
            database: AppDatabase? = AppDatabase.shared,
            importError: Error? = AppDatabase.sharedLegacyImportError,
            logManager: LogManagerProtocol = LogManager.shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared
        ) {
            self.database = database
            self.importError = importError
            self.logManager = logManager
            self.notificationManager = notificationManager
        }
    }

    let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func run() {
        if let importError = dependency.importError {
            dependency.logManager.sendEvent(event: CustomEvent(
                screen: .appLaunch,
                name: .dbMigration,
                extraParameters: [.result: "failure", .errorType: "\((importError as NSError).domain):\((importError as NSError).code)"]
            ))
            return
        }

        guard let database = dependency.database,
              let report = LegacyRealmImporter.pendingReport(in: database)
        else { return }

        // 겹친 id 때문에 새 id 를 받은 알림만 새로 예약한다. 같은 id 의 기존 예약은 원래 위시 것이라 그대로 둔다 (R-23)
        let repository = WishRepositoryImpl(database: database)
        for wishId in report.rescheduleWishIds {
            guard let wish = repository.fetchWish(id: wishId) else { continue }
            dependency.notificationManager.reserveNotifications(wish: wish)
        }

        dependency.logManager.sendEvent(event: CustomEvent(
            screen: .appLaunch,
            name: .dbMigration,
            extraParameters: [
                .result: "success",
                .wishCount: report.wishCount,
                .reassignedIdCount: report.reassignedIdCount
            ]
        ))
        // 이벤트는 한 번만 보낸다 (TC-16)
        LegacyRealmImporter.clearPendingReport(in: database)
    }
}
