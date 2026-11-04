import Foundation

import GRDB

/// 동기화의 로컬 쪽: 아웃박스·syncState 읽기/쓰기와 받은 문서 적용 (GH-93, 설계 §5·§6.2). GRDB 접근은 여기서만 한다(R3)
final class SyncStore {
    enum StateKey {
        static let uid = "uid"
        /// 이 기기 로컬 데이터가 묶인 계정 (설계 §6.3)
        static let boundUid = "boundUid"
        static let lastSyncedAt = "lastSyncedAt"
        static func cursor(_ collection: SyncCollection) -> String { "cursor.\(collection.rawValue)" }
    }

    /// 적용 결과
    struct ApplyResult: Equatable {
        /// 로컬이 바뀐 위시 (알림 다시 예약·위젯 갱신용)
        var changedWishIds: Set<String> = []
        /// 부모 위시가 아직 없어 다음 사이클로 미룬 문서
        var deferred: [SyncDocument] = []
    }

    private let database: AppDatabase?

    init(database: AppDatabase? = AppDatabase.shared) {
        self.database = database
    }

    /// 지금 앱이 아는 마지막 마이그레이션 (`schemaVersion`, 설계 §6.4)
    var schemaVersion: String {
        (try? database?.writer.read { db in
            try String.fetchOne(db, sql: "SELECT identifier FROM grdb_migrations ORDER BY rowid DESC LIMIT 1")
        }).flatMap { $0 } ?? ""
    }

    // MARK: syncState

    func value(_ key: String) -> String? {
        try? database?.writer.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM syncState WHERE key = ?", arguments: [key])
        }
    }

    func setValue(_ value: String?, for key: String) {
        _ = try? database?.writer.write { db in
            if let value {
                try db.execute(sql: "INSERT OR REPLACE INTO syncState (key, value) VALUES (?, ?)", arguments: [key, value])
            } else {
                try db.execute(sql: "DELETE FROM syncState WHERE key = ?", arguments: [key])
            }
        }
    }

    func cursor(_ collection: SyncCollection) -> RemoteTimestamp? {
        value(StateKey.cursor(collection)).flatMap(RemoteTimestamp.init(stored:))
    }

    func setCursor(_ cursor: RemoteTimestamp?, for collection: SyncCollection) {
        setValue(cursor?.stored, for: StateKey.cursor(collection))
    }

    func clearCursors() {
        SyncCollection.allCases.forEach { setCursor(nil, for: $0) }
    }

    // MARK: 아웃박스

    func pendingCount() -> Int {
        (try? database?.writer.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(DISTINCT tableName || ':' || rowId) FROM syncOutbox")
        }).flatMap { $0 } ?? 0
    }

    /// 큐 앞에서부터 최대 `limit`줄을 읽어, 줄마다 **지금 로컬 값**을 돌려준다. 같은 줄은 한 번만.
    /// 로컬에서 줄이 사라졌으면(이 기기에서 지우기) 건너뛴다
    func pendingDocuments(limit: Int) -> (lastSeq: Int64, documents: [SyncDocument])? {
        try? database?.writer.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT seq, tableName, rowId FROM syncOutbox ORDER BY seq LIMIT ?", arguments: [limit])
            guard let last = rows.last else { return nil }
            var seen = Set<String>()
            var documents: [SyncDocument] = []
            for row in rows {
                let tableName: String = row["tableName"]
                let rowId: String = row["rowId"]
                guard let collection = SyncCollection(tableName: tableName), seen.insert("\(tableName):\(rowId)").inserted else { continue }
                if let document = try Self.document(collection: collection, id: rowId, in: db) {
                    documents.append(document)
                }
            }
            return (last["seq"], documents)
        } ?? nil
    }

    func removeOutbox(upTo seq: Int64) {
        _ = try? database?.writer.write { db in
            try db.execute(sql: "DELETE FROM syncOutbox WHERE seq <= ?", arguments: [seq])
        }
    }

    func clearOutbox() {
        _ = try? database?.writer.write { db in
            try db.execute(sql: "DELETE FROM syncOutbox")
        }
    }

    /// 처음 로그인할 때 올릴 로컬 전체(삭제 표시 포함, 설계 §6.3)
    func allDocuments() -> [SyncDocument] {
        (try? database?.writer.read { db in
            try SyncCollection.allCases.flatMap { collection in
                try Row.fetchAll(db, sql: "SELECT * FROM \(collection.tableName)").map { Self.document(collection: collection, row: $0) }
            }
        }) ?? []
    }

    // MARK: 받은 문서 적용

    /// 줄 단위 LWW(`updatedAt`) + 삭제 우선으로 한 트랜잭션에 적용한다 (설계 §6.2).
    /// 적용하며 트리거가 쌓은 아웃박스 줄은 되돌려 보내지 않게 지운다
    func apply(_ documents: [SyncDocument]) -> ApplyResult {
        guard let database else { return ApplyResult(deferred: documents) }
        let ordered = documents.sorted { lhs, rhs in
            (SyncCollection.allCases.firstIndex(of: lhs.collection) ?? 0) < (SyncCollection.allCases.firstIndex(of: rhs.collection) ?? 0)
        }
        return (try? database.writer.write { db in
            let startSeq = try Int64.fetchOne(db, sql: "SELECT COALESCE(MAX(seq), 0) FROM syncOutbox") ?? 0
            var result = ApplyResult()
            var resendLocal: [(SyncCollection, String)] = []
            for document in ordered {
                if document.collection.isChild {
                    let parentId = document.wishId ?? ""
                    let parentExists = try Bool.fetchOne(db, sql: "SELECT EXISTS(SELECT 1 FROM wish WHERE id = ?)", arguments: [parentId]) ?? false
                    guard parentExists else {
                        result.deferred.append(document)
                        continue
                    }
                }
                switch try Self.decide(document, in: db) {
                case .write:
                    // 한 문서가 깨져 있어도(필수 컬럼 없음 등) 나머지는 적용하고, 그 문서는 건너뛴다
                    guard (try? Self.write(document, in: db)) != nil else { continue }
                    if let wishId = document.wishId { result.changedWishIds.insert(wishId) }
                case .skip:
                    break
                case .resendLocal:
                    // 서버 값이 로컬보다 오래됐다(늦게 올라온 옛 값, 또는 로컬에서 지운 줄이 서버엔 살아 있음). 로컬 값을 다시 올린다
                    resendLocal.append((document.collection, document.id))
                }
            }
            try db.execute(sql: "DELETE FROM syncOutbox WHERE seq > ?", arguments: [startSeq])
            for (collection, id) in resendLocal {
                try db.execute(
                    sql: "INSERT INTO syncOutbox (tableName, rowId, enqueuedAt) VALUES (?, ?, ?)",
                    arguments: [collection.tableName, id, Date().timeIntervalSinceReferenceDate]
                )
            }
            return result
        }) ?? ApplyResult(deferred: documents)
    }

    // MARK: - Private

    private enum Decision {
        case write
        case skip
        case resendLocal
    }

    private static func decide(_ remote: SyncDocument, in db: Database) throws -> Decision {
        guard let local = try document(collection: remote.collection, id: remote.id, in: db) else { return .write }
        // 삭제가 이긴다: 지운 위시가 되살아나는 것이 더 나쁘다
        if remote.isDeleted && !local.isDeleted { return .write }
        if local.isDeleted && !remote.isDeleted { return .resendLocal }
        if remote.updatedAt > local.updatedAt { return .write }
        // 다른 기기가 오프라인에서 고친 옛 값을 나중에 올리면 서버가 더 새 값을 덮는다. 더 새 쪽이 다시 올려 맞춘다
        return remote.updatedAt < local.updatedAt ? .resendLocal : .skip
    }

    /// 로컬 테이블에 있는 컬럼만 쓴다. 더 새 앱이 만든 모르는 필드는 버린다 (설계 §6.4)
    private static func write(_ document: SyncDocument, in db: Database) throws {
        let columns = try db.columns(in: document.collection.tableName).map(\.name)
        let known = columns.filter { document.fields[$0] != nil || $0 == "id" }
        var values: [DatabaseValueConvertible?] = []
        for column in known {
            values.append(column == "id" ? document.id : databaseValue(document.fields[column] ?? .null))
        }
        let placeholders = Array(repeating: "?", count: known.count).joined(separator: ", ")
        let quoted = known.map { "\"\($0)\"" }.joined(separator: ", ")
        let updates = known.filter { $0 != "id" }.map { "\"\($0)\" = excluded.\"\($0)\"" }.joined(separator: ", ")
        try db.execute(
            sql: "INSERT INTO \(document.collection.tableName) (\(quoted)) VALUES (\(placeholders)) ON CONFLICT(id) DO UPDATE SET \(updates)",
            arguments: StatementArguments(values)
        )
    }

    private static func document(collection: SyncCollection, id: String, in db: Database) throws -> SyncDocument? {
        try Row.fetchOne(db, sql: "SELECT * FROM \(collection.tableName) WHERE id = ?", arguments: [id])
            .map { document(collection: collection, row: $0) }
    }

    private static func document(collection: SyncCollection, row: Row) -> SyncDocument {
        var fields: [String: SyncValue] = [:]
        for (column, value) in row where column != "id" {
            fields[column] = syncValue(value)
        }
        return SyncDocument(collection: collection, id: row["id"], fields: fields)
    }

    private static func syncValue(_ value: DatabaseValue) -> SyncValue {
        switch value.storage {
        case .null: return .null
        case .int64(let int): return .integer(int)
        case .double(let double): return .double(double)
        case .string(let string): return .text(string)
        case .blob(let data): return .blob(data)
        }
    }

    private static func databaseValue(_ value: SyncValue) -> DatabaseValueConvertible? {
        switch value {
        case .null: return nil
        case .integer(let int): return int
        case .double(let double): return double
        case .text(let string): return string
        case .blob(let data): return data
        }
    }
}
