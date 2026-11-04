import Foundation

/// 로컬 SQLite 값 ⇄ Firestore 값 사이의 공통 표현. 엔진·저장소가 Firebase·GRDB 타입을 서로 모르게 한다 (GH-93)
enum SyncValue: Equatable {
    case null
    case integer(Int64)
    case double(Double)
    case text(String)
    case blob(Data)

    var doubleValue: Double? {
        switch self {
        case .integer(let value): return Double(value)
        case .double(let value): return value
        default: return nil
        }
    }

    var stringValue: String? {
        if case .text(let value) = self { return value }
        return nil
    }

    var isNull: Bool { self == .null }
}

/// 동기화하는 테이블 하나 = Firestore 최상위 컬렉션 하나 (설계 §4). 순서는 부모(`wish`)가 먼저
enum SyncCollection: String, CaseIterable {
    case wish
    case wishStep
    case wishSaving
    case wishNotification
    case wishJournal

    var tableName: String { rawValue }

    var collectionName: String {
        switch self {
        case .wish: return "wishes"
        case .wishStep: return "wishSteps"
        case .wishSaving: return "wishSavings"
        case .wishNotification: return "wishNotifications"
        case .wishJournal: return "wishJournals"
        }
    }

    var isChild: Bool { self != .wish }

    init?(tableName: String) {
        self.init(rawValue: tableName)
    }
}

/// Firestore `serverUpdatedAt`. 받아오기 커서로 쓴다 (기기 시계와 무관)
struct RemoteTimestamp: Comparable, Equatable {
    let seconds: Int64
    let nanoseconds: Int32

    static func < (lhs: RemoteTimestamp, rhs: RemoteTimestamp) -> Bool {
        (lhs.seconds, lhs.nanoseconds) < (rhs.seconds, rhs.nanoseconds)
    }

    /// `syncState`에 문자열로 둔다
    var stored: String { "\(seconds):\(nanoseconds)" }

    init(seconds: Int64, nanoseconds: Int32) {
        self.seconds = seconds
        self.nanoseconds = nanoseconds
    }

    init?(stored: String) {
        let parts = stored.split(separator: ":")
        guard parts.count == 2, let seconds = Int64(parts[0]), let nanoseconds = Int32(parts[1]) else { return nil }
        self.init(seconds: seconds, nanoseconds: nanoseconds)
    }
}

/// 서버와 주고받는 문서 하나. `fields`는 로컬 컬럼 이름 그대로다(ownerUid 등 서버 전용 필드는 빠진다)
struct SyncDocument: Equatable {
    let collection: SyncCollection
    let id: String
    var fields: [String: SyncValue]
    /// 받은 문서에만 있다
    var serverUpdatedAt: RemoteTimestamp?

    var updatedAt: Double { fields["updatedAt"]?.doubleValue ?? 0 }
    var isDeleted: Bool { !(fields["deletedAt"]?.isNull ?? true) }
    /// 이 문서가 속한 위시. 위시면 자기 id, 하위 문서면 `wishId`
    var wishId: String? { collection == .wish ? id : fields["wishId"]?.stringValue }
}

/// push 할 때 서버 문서에 같이 쓰는 값
struct SyncMetadata: Equatable {
    let ownerUid: String
    let schemaVersion: String
}
