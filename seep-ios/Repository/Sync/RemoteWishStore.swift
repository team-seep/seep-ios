import Foundation

import FirebaseFirestore

/// 서버 쪽 위시 문서 (GH-93, 설계 §4). Firestore 접근은 여기서만 한다(R11). 테스트는 메모리 목으로 바꾼다
protocol RemoteWishStore {
    /// `merge: true`로 쓴다. 구버전 앱이 모르는 필드를 지우지 않는다 (설계 §6.4)
    func push(_ documents: [SyncDocument], metadata: SyncMetadata) async throws

    /// `serverUpdatedAt`이 `cursor`보다 큰 내 문서를 오래된 순으로
    func pull(_ collection: SyncCollection, uid: String, after cursor: RemoteTimestamp?) async throws -> [SyncDocument]
}

final class FirestoreRemoteWishStore: RemoteWishStore {
    private enum Field {
        static let ownerUid = "ownerUid"
        static let memberUids = "memberUids"
        static let serverUpdatedAt = "serverUpdatedAt"
        static let schemaVersion = "schemaVersion"
        /// TTL 정책 필드 (firestore.indexes.json `fieldOverrides`). 삭제 표시 문서에만 쓴다
        static let purgeAt = "purgeAt"
        static let serverOnly: Set<String> = [ownerUid, memberUids, serverUpdatedAt, schemaVersion, purgeAt]
    }

    /// Firestore 배치 한도(500)보다 조금 작게
    private static let batchLimit = 450
    private static let pageSize = 500

    private lazy var firestore: Firestore = {
        let firestore = Firestore.firestore()
        // 로컬 기준 데이터는 GRDB 다. Firestore 디스크 캐시까지 두면 같은 데이터를 두 번 저장한다 (설계 §3)
        let settings = firestore.settings
        settings.cacheSettings = MemoryCacheSettings()
        firestore.settings = settings
        return firestore
    }()

    func push(_ documents: [SyncDocument], metadata: SyncMetadata) async throws {
        for start in stride(from: 0, to: documents.count, by: Self.batchLimit) {
            let batch = firestore.batch()
            for document in documents[start..<min(start + Self.batchLimit, documents.count)] {
                var data = document.fields.mapValues(Self.firestoreValue)
                data[Field.ownerUid] = metadata.ownerUid
                data[Field.memberUids] = [metadata.ownerUid]
                data[Field.schemaVersion] = metadata.schemaVersion
                data[Field.serverUpdatedAt] = FieldValue.serverTimestamp()
                // 살아 있는 문서는 TTL 필드를 지운다. 늦게 올라온 옛 값이 삭제 표시를 잠시 덮어도 서버가 살아 있는 문서를 지우지 않게 한다
                data[Field.purgeAt] = document.isDeleted ? Timestamp(date: metadata.purgeAt) : FieldValue.delete()
                let reference = firestore.collection(document.collection.collectionName).document(document.id)
                batch.setData(data, forDocument: reference, merge: true)
            }
            try await batch.commit()
        }
    }

    func pull(_ collection: SyncCollection, uid: String, after cursor: RemoteTimestamp?) async throws -> [SyncDocument] {
        var query: Query = firestore.collection(collection.collectionName)
            .whereField(Field.memberUids, arrayContains: uid)
        if let cursor {
            query = query.whereField(Field.serverUpdatedAt, isGreaterThan: Timestamp(seconds: cursor.seconds, nanoseconds: cursor.nanoseconds))
        }
        query = query.order(by: Field.serverUpdatedAt).limit(to: Self.pageSize)

        var documents: [SyncDocument] = []
        var lastSnapshot: DocumentSnapshot?
        while true {
            // 한 배치로 쓴 문서는 serverUpdatedAt 이 같다. 페이지는 시각이 아니라 마지막 문서 다음부터 이어 받아야 빠지지 않는다
            let page = try await (lastSnapshot.map { query.start(afterDocument: $0) } ?? query).getDocuments()
            documents += page.documents.compactMap { Self.document(collection: collection, snapshot: $0) }
            guard page.documents.count == Self.pageSize, let last = page.documents.last else { break }
            lastSnapshot = last
        }
        return documents
    }

    private static func document(collection: SyncCollection, snapshot: QueryDocumentSnapshot) -> SyncDocument? {
        let data = snapshot.data()
        // 쓰는 중이라 serverTimestamp 가 아직 없는 문서는 다음에 받는다
        guard let timestamp = data[Field.serverUpdatedAt] as? Timestamp else { return nil }
        var fields: [String: SyncValue] = [:]
        for (key, value) in data where !Field.serverOnly.contains(key) {
            fields[key] = syncValue(value)
        }
        return SyncDocument(
            collection: collection,
            id: snapshot.documentID,
            fields: fields,
            serverUpdatedAt: RemoteTimestamp(seconds: timestamp.seconds, nanoseconds: timestamp.nanoseconds)
        )
    }

    private static func firestoreValue(_ value: SyncValue) -> Any {
        switch value {
        case .null: return NSNull()
        case .integer(let int): return int
        case .double(let double): return double
        case .text(let string): return string
        case .blob(let data): return data
        }
    }

    private static func syncValue(_ value: Any) -> SyncValue {
        switch value {
        case is NSNull:
            return .null
        case let string as String:
            return .text(string)
        case let data as Data:
            return .blob(data)
        case let number as NSNumber:
            // Firestore 는 정수·실수·불 모두 NSNumber 로 준다. 정수 컬럼은 SQLite 친화도가 맞춰 바꾼다
            return CFNumberIsFloatType(number) ? .double(number.doubleValue) : .integer(number.int64Value)
        default:
            return .null
        }
    }
}
