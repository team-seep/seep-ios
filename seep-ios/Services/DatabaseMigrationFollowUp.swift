import Foundation

/// Realm → GRDB 1회 이전 뒤 앱이 할 일 (GH-79 R-22, R-23). 앱 실행 때 한 번 돈다.
/// 이전은 위젯이 먼저 했을 수도 있어서, 결과를 DB(`appMetadata`)에서 꺼내 처리하고 지운다.
/// 홈 카드 "다시 시도"(GH-96 R-10)와 원격 재이전(GH-96 R-3)도 여기서 이벤트·알림 재예약을 맡는다
struct DatabaseMigrationFollowUp {
    /// `db_migration` 이벤트가 어디서 났는지 (GH-96)
    enum Trigger: String {
        /// 앱 실행 때 1회 이전
        case launch
        /// 홈 카드 [다시 시도]
        case retry
        /// Remote Config 재이전 스위치
        case reimport
    }

    struct Dependency {
        let database: AppDatabase?
        /// 이번 실행에서 이전하다 난 오류. 있으면 실패 이벤트를 보낸다
        let importError: Error?
        let logManager: LogManagerProtocol
        let notificationManager: NotificationManagerProtocol
        /// 재이전이 읽을 원본. 테스트는 임시 Realm 파일을 넘긴다
        let importer: LegacyRealmImporter

        init(
            database: AppDatabase? = AppDatabase.shared,
            importError: Error? = AppDatabase.sharedLegacyImportError,
            logManager: LogManagerProtocol = LogManager.shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            importer: LegacyRealmImporter = LegacyRealmImporter()
        ) {
            self.database = database
            self.importError = importError
            self.logManager = logManager
            self.notificationManager = notificationManager
            self.importer = importer
        }
    }

    let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func run(trigger: Trigger = .launch) {
        if let importError = dependency.importError {
            sendFailure(importError, trigger: trigger)
            return
        }

        guard let database = dependency.database,
              let report = LegacyRealmImporter.pendingReport(in: database)
        else { return }

        // 겹친 id 때문에 새 id 를 받은 알림만 새로 예약한다. 같은 id 의 기존 예약은 원래 위시 것이라 그대로 둔다 (R-23)
        reserveNotifications(wishIds: report.rescheduleWishIds, in: database)

        dependency.logManager.sendEvent(event: CustomEvent(
            screen: .appLaunch,
            name: .dbMigration,
            extraParameters: [
                .result: "success",
                .trigger: trigger.rawValue,
                .wishCount: report.wishCount,
                .realmWishCount: report.realmWishCount,
                .reassignedIdCount: report.reassignedIdCount
            ]
        ))
        // 이벤트는 한 번만 보낸다 (TC-16)
        LegacyRealmImporter.clearPendingReport(in: database)
    }

    /// Remote Config 토큰이 새 값이면 원본 Realm 에서 빠진 줄만 다시 넣는다 (GH-96 R-3~R-7).
    /// 돌아온 위시 수를 돌려준다. 돌지 않았거나 실패하면 0
    @discardableResult
    func reimportIfRequested(token: String) -> Int {
        guard let database = dependency.database else { return 0 }
        do {
            guard let report = try dependency.importer.reimportMissing(into: database, token: token) else { return 0 }
            reserveNotifications(wishIds: report.rescheduleWishIds, in: database)
            dependency.logManager.sendEvent(event: CustomEvent(
                screen: .appLaunch,
                name: .dbMigration,
                extraParameters: [
                    .result: "success",
                    .trigger: Trigger.reimport.rawValue,
                    .restoredWishCount: report.restoredWishIds.count,
                    .restoredRowCount: report.restoredRowCount
                ]
            ))
            return report.restoredWishIds.count
        } catch {
            // 토큰을 저장하지 않았으니 다음 실행에서 다시 시도한다 (R-4)
            sendFailure(error, trigger: .reimport)
            return 0
        }
    }

    /// 이벤트·문의 메일에 쓰는 오류 종류 `domain:code`
    static func errorType(_ error: Error) -> String {
        let nsError = error as NSError
        return "\(nsError.domain):\(nsError.code)"
    }

    private func reserveNotifications(wishIds: [String], in database: AppDatabase) {
        let repository = WishRepositoryImpl(database: database)
        for wishId in wishIds {
            // 지운 위시(삭제 표시)는 읽히지 않아 예약하지 않는다
            guard let wish = repository.fetchWish(id: wishId) else { continue }
            dependency.notificationManager.reserveNotifications(wish: wish)
        }
    }

    private func sendFailure(_ error: Error, trigger: Trigger) {
        dependency.logManager.sendEvent(event: CustomEvent(
            screen: .appLaunch,
            name: .dbMigration,
            extraParameters: [.result: "failure", .trigger: trigger.rawValue, .errorType: Self.errorType(error)]
        ))
    }
}
