import Foundation
import os
import SQLite3

import GRDB

/// 앱·위젯이 같이 여는 App Group SQLite (GH-79 R-10). 스키마·마이그레이션은 이 한 곳에서 정한다.
/// 동기화 대비 규칙: PK 는 UUID 문자열, 모든 테이블에 `updatedAt`·`deletedAt`, PK 외 UNIQUE 없음, 하위 테이블은 `wishId`만 참조 (R-3~R-8).
final class AppDatabase {
    static let appGroupIdentifier = "group.macgongmon.seep-ios"

    /// 앱·위젯 공용 DB. 열지 못하면 nil 이고, Repository 는 `.noDatabase`를 돌려준다
    static let shared: AppDatabase? = openShared()

    /// 마지막 1회 이전에서 난 오류. 앱이 `db_migration` 실패 이벤트로 보낸다 (R-22)
    private(set) static var sharedLegacyImportError: Error?

    let writer: any DatabaseWriter

    private static let logger = Logger(subsystem: "macgongmon.seep-ios", category: "AppDatabase")

    /// 마이그레이션까지 끝낸 DB 를 감싼다. 테스트는 `DatabaseQueue()`(메모리)를 넘긴다
    init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// 테스트·미리보기용 메모리 DB
    static func makeInMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    // MARK: - 스키마

    // 배포된 마이그레이션은 고치지 않고 새로 추가한다 (RULES R4, scripts/check-db-schema.sh)
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: WishRecord.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.column("category", .text).notNull()
                table.column("emoji", .text).notNull().defaults(to: "")
                table.column("title", .text).notNull().defaults(to: "")
                table.column("date", .double)
                table.column("finishDate", .double)
                table.column("targetAmount", .integer).notNull().defaults(to: 0)
                table.column("memo", .text).notNull().defaults(to: "")
                table.column("hashtag", .text).notNull().defaults(to: "")
                table.column("isSuccess", .boolean).notNull().defaults(to: false)
                table.column("finishNote", .text).notNull().defaults(to: "")
                table.column("pinnedAt", .double)
                table.column("link", .text).notNull().defaults(to: "")
                table.column("lastCheckedAt", .double)
                table.column("placeName", .text).notNull().defaults(to: "")
                table.column("placeAddress", .text).notNull().defaults(to: "")
                table.column("latitude", .double).notNull().defaults(to: 0)
                table.column("longitude", .double).notNull().defaults(to: 0)
                table.column("photoFileName", .text).notNull().defaults(to: "")
                table.column("createdAt", .double).notNull()
                table.column("updatedAt", .double).notNull()
                table.column("deletedAt", .double)
            }
            // 정렬·필터용 일반 인덱스. UNIQUE 는 두지 않는다 (R-7)
            for column in ["category", "isSuccess", "finishDate", "pinnedAt", "date", "deletedAt"] {
                try db.create(index: "wish_on_\(column)", on: WishRecord.databaseTableName, columns: [column])
            }

            try db.create(table: WishStepRecord.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.belongsTo("wish", onDelete: .cascade).notNull()
                table.column("title", .text).notNull().defaults(to: "")
                table.column("isDone", .boolean).notNull().defaults(to: false)
                table.column("order", .integer).notNull().defaults(to: 0)
                table.column("updatedAt", .double).notNull()
                table.column("deletedAt", .double)
            }

            try db.create(table: WishSavingRecord.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.belongsTo("wish", onDelete: .cascade).notNull()
                table.column("amount", .integer).notNull().defaults(to: 0)
                table.column("createdAt", .double).notNull()
                table.column("updatedAt", .double).notNull()
                table.column("deletedAt", .double)
            }

            try db.create(table: WishNotificationRecord.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.belongsTo("wish", onDelete: .cascade).notNull()
                table.column("type", .text).notNull()
                table.column("time", .double).notNull()
                table.column("order", .integer).notNull().defaults(to: 0)
                table.column("updatedAt", .double).notNull()
                table.column("deletedAt", .double)
            }

            // 이 기기에만 있는 값(1회 이전 표시 등). 동기화 대상이 아니다
            try db.create(table: "appMetadata") { table in
                table.primaryKey("key", .text)
                table.column("value", .text).notNull()
            }
        }

        // GH-61: "미래의 나에게" 편지. 기존 위시는 편지 없음
        migrator.registerMigration("v2") { db in
            try db.alter(table: WishRecord.databaseTableName) { table in
                table.add(column: "futureLetter", .text).notNull().defaults(to: "")
                table.add(column: "futureLetterSealedAt", .double)
            }
        }

        // GH-73: "내가 정한 순서". 기존 위시는 카테고리마다 최근 생성순(1, 2, 3 …)으로 채운다
        migrator.registerMigration("v3") { db in
            try db.alter(table: WishRecord.databaseTableName) { table in
                table.add(column: "manualOrder", .double).notNull().defaults(to: 0)
            }
            try db.execute(sql: """
                UPDATE wish SET manualOrder = (
                    SELECT ranked.position FROM (
                        SELECT id, ROW_NUMBER() OVER (PARTITION BY category ORDER BY createdAt DESC) AS position FROM wish
                    ) AS ranked
                    WHERE ranked.id = wish.id
                )
                """)
        }

        // GH-84: 싶 잇기. 기존 위시는 앞 위시 없음
        migrator.registerMigration("v4") { db in
            try db.alter(table: WishRecord.databaseTableName) { table in
                table.add(column: "previousWishId", .text)
            }
            try db.create(index: "wish_on_previousWishId", on: WishRecord.databaseTableName, columns: ["previousWishId"])
        }

        // GH-95: 싶 일지. 동기화 대비로 wishId 에 FK 를 두지 않고 일반 인덱스만 둔다. 기존 위시는 일지 0개
        migrator.registerMigration("v5") { db in
            try db.create(table: WishJournalRecord.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.column("wishId", .text).notNull()
                table.column("text", .text).notNull().defaults(to: "")
                table.column("createdAt", .double).notNull()
                table.column("updatedAt", .double).notNull()
                table.column("deletedAt", .double)
            }
            try db.create(index: "wishJournal_on_wishId", on: WishJournalRecord.databaseTableName, columns: ["wishId"])
        }

        return migrator
    }

    // MARK: - appMetadata

    static func metadataValue(_ key: String, in db: Database) throws -> String? {
        try String.fetchOne(db, sql: "SELECT value FROM appMetadata WHERE key = ?", arguments: [key])
    }

    static func setMetadata(_ key: String, value: String?, in db: Database) throws {
        if let value {
            try db.execute(sql: "INSERT OR REPLACE INTO appMetadata (key, value) VALUES (?, ?)", arguments: [key, value])
        } else {
            try db.execute(sql: "DELETE FROM appMetadata WHERE key = ?", arguments: [key])
        }
    }

    // MARK: - App Group 공유 DB

    private static func openShared() -> AppDatabase? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            logger.error("App Group 컨테이너를 찾지 못했다")
            return nil
        }
        // 개발 앱·운영 앱이 같은 App Group 을 쓰므로 Realm 이름(dev.realm / default.realm)에서 파일 이름을 딴다
        let fileName = (Bundle.realmName as NSString).deletingPathExtension + ".sqlite"
        let databaseURL = container.appendingPathComponent(fileName)
        let isApp = Bundle.main.bundleURL.pathExtension != "appex"

        // 앱·위젯이 동시에 만들거나 마이그레이션하지 않게 파일 코디네이션으로 감싼다 (GRDB "Sharing a Database")
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var database: AppDatabase?
        coordinator.coordinate(writingItemAt: databaseURL, options: .forMerging, error: &coordinatorError) { url in
            do {
                database = try AppDatabase(makeSharedPool(at: url))
            } catch {
                logger.error("DB 를 열지 못했다: \(error.localizedDescription, privacy: .public)")
                return
            }
            guard let database else { return }
            do {
                try LegacyRealmImporter().importIfNeeded(into: database, markWhenNoRealmFile: isApp)
            } catch {
                // 실패하면 아무것도 남기지 않고(트랜잭션) 다음 실행에서 처음부터 다시 한다 (R-19)
                sharedLegacyImportError = error
                logger.error("Realm 이전 실패: \(error.localizedDescription, privacy: .public)")
            }
        }
        if let coordinatorError {
            logger.error("DB 파일 코디네이션 실패: \(coordinatorError.localizedDescription, privacy: .public)")
        }
        return database
    }

    private static func makeSharedPool(at url: URL) throws -> DatabasePool {
        var configuration = Configuration()
        // 다른 프로세스가 쓰는 중이면 바로 실패하지 않고 기다린다
        configuration.busyMode = .timeout(5)
        // 앱이 정지될 때 잠금을 쥔 채로 멈춰 강제 종료(0xdead10cc)되지 않게 한다 (R-11). 알림은 AppDelegate 가 보낸다
        configuration.observesSuspensionNotifications = true
        configuration.prepareDatabase { db in
            // persistent WAL: -shm·-wal 파일을 지우지 않아 다른 프로세스가 언제든 열 수 있다
            if db.configuration.readonly == false {
                var flag: CInt = 1
                let code = withUnsafeMutablePointer(to: &flag) { flagPointer in
                    sqlite3_file_control(db.sqliteConnection, nil, SQLITE_FCNTL_PERSIST_WAL, flagPointer)
                }
                guard code == SQLITE_OK else {
                    throw DatabaseError(resultCode: ResultCode(rawValue: code))
                }
            }
        }
        return try DatabasePool(path: url.path, configuration: configuration)
    }
}

// MARK: - 검사용

extension AppDatabase {
    /// 삭제 표시한 줄까지 테이블 내용을 그대로 읽는다. 1회 이전·삭제 표시를 확인하는 테스트용
    struct Snapshot {
        let wishes: [WishRecord]
        let steps: [WishStepRecord]
        let savings: [WishSavingRecord]
        let notifications: [WishNotificationRecord]
        let journals: [WishJournalRecord]
        let metadata: [String: String]
    }

    func snapshot() throws -> Snapshot {
        try writer.read { db in
            Snapshot(
                wishes: try WishRecord.fetchAll(db),
                steps: try WishStepRecord.fetchAll(db),
                savings: try WishSavingRecord.fetchAll(db),
                notifications: try WishNotificationRecord.fetchAll(db),
                journals: try WishJournalRecord.fetchAll(db),
                metadata: Dictionary(
                    uniqueKeysWithValues: try Row.fetchAll(db, sql: "SELECT key, value FROM appMetadata")
                        .map { (row: Row) -> (String, String) in (row["key"], row["value"]) }
                )
            )
        }
    }

    /// 예전 스키마(`version`까지 마이그레이션)에 `seedSQL`로 데이터를 넣은 뒤 최신까지 올린 메모리 DB. 마이그레이션 테스트용
    static func makeInMemory(migratedUpTo version: String, seedSQL: [String]) throws -> AppDatabase {
        let queue = try DatabaseQueue()
        try migrator.migrate(queue, upTo: version)
        try queue.write { db in
            for sql in seedSQL {
                try db.execute(sql: sql)
            }
        }
        return try AppDatabase(queue)
    }

    /// 테스트에서 이전 도중 실패를 만들려고 위시 한 줄을 직접 넣는다
    func insertRecord(_ record: WishRecord) throws {
        try writer.write { try record.insert($0) }
    }

    func deleteRecord(_ record: WishRecord) throws {
        _ = try writer.write { try record.delete($0) }
    }
}

