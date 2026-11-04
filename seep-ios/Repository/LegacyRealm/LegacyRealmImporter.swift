import CryptoKit
import Foundation

import GRDB
import RealmSwift

/// Realm → GRDB 1회 이전 (GH-79 R-17~R-19, R-23).
/// 앱·위젯 중 먼저 DB 를 여는 쪽이 한다. 업데이트 뒤 앱보다 위젯이 먼저 갱신돼도 기존 위시가 보이게 하기 위해서다 (TC-11).
struct LegacyRealmImporter {
    /// 이전 결과. 이벤트(`db_migration`)와 알림 재예약은 앱이 다음 실행에서 처리한다 (위젯은 GA·알림 매니저를 못 쓴다)
    struct Report: Codable, Equatable {
        /// 이전 뒤 GRDB 에 들어간 위시 수
        var wishCount: Int
        /// 원본 Realm 의 위시 수. `wishCount`와 다르면 GA 에서 바로 보인다 (GH-96 R-15)
        var realmWishCount: Int
        /// 이미 옮긴 id 와 겹치거나 비어 있어 새 UUID 를 붙인 레코드 수 (R-18)
        var reassignedIdCount: Int
        /// 새 id 를 받은 알림이 있는 위시. 새 id 로 다시 예약해야 한다 (R-23)
        var rescheduleWishIds: [String]
    }

    /// 원격 재이전 결과 (GH-96 R-4~R-7)
    struct ReimportReport: Equatable {
        /// 새로 들어간 위시
        var restoredWishIds: [String]
        /// 새로 들어간 단계·저금·알림 줄 수
        var restoredRowCount: Int
        /// 알림을 다시 예약할 위시 (새로 들어간 위시 + 알림 줄이 새로 들어간 위시)
        var rescheduleWishIds: [String]
    }

    enum MetadataKey {
        static let completedAt = "legacyRealmImport.completedAt"
        static let pendingReport = "legacyRealmImport.pendingReport"
        /// 마지막으로 처리한 재이전 토큰 (GH-96 R-3)
        static let reimportToken = "legacyRealmImport.reimportToken"
    }

    let realmFileURL: URL?
    let now: () -> Date

    init(realmFileURL: URL? = LegacyRealmConfiguration.sharedFileURL, now: @escaping () -> Date = Date.init) {
        self.realmFileURL = realmFileURL
        self.now = now
    }

    /// 아직 안 했으면 이전한다. 이미 했거나 Realm 파일이 없으면 nil.
    /// - Parameter markWhenNoRealmFile: Realm 파일이 없을 때 "이전 끝"으로 표시할지. 앱만 true —
    ///   아주 오래된 사용자는 앱이 실행될 때 기본 위치의 Realm 을 App Group 으로 옮기므로(AppDelegate) 위젯이 먼저 끝으로 표시하면 안 된다
    @discardableResult
    func importIfNeeded(into database: AppDatabase, markWhenNoRealmFile: Bool) throws -> Report? {
        let writer = database.writer
        let isCompleted = try writer.read { db in
            try AppDatabase.metadataValue(MetadataKey.completedAt, in: db) != nil
        }
        guard !isCompleted else { return nil }

        guard let realmFileURL, FileManager.default.fileExists(atPath: realmFileURL.path) else {
            if markWhenNoRealmFile {
                try writer.write { db in
                    try AppDatabase.setMetadata(MetadataKey.completedAt, value: Self.timestamp(now()), in: db)
                }
            }
            return nil
        }

        // Realm 객체는 연 스레드에서만 쓸 수 있어서, GRDB 쓰기 큐로 넘어가기 전에 레코드(값)로 다 옮긴다
        let prepared = try prepareRecords(realmFileURL: realmFileURL, importedAt: now())
        return try writer.write { db -> Report? in
            // 다른 프로세스가 그 사이에 끝냈으면 넘어간다. 확인과 쓰기가 한 트랜잭션이라 두 번 들어가지 않는다 (R-19, TC-4)
            guard try AppDatabase.metadataValue(MetadataKey.completedAt, in: db) == nil else { return nil }
            try prepared.wishes.forEach { try $0.insert(db) }
            try prepared.steps.forEach { try $0.insert(db) }
            try prepared.savings.forEach { try $0.insert(db) }
            try prepared.notifications.forEach { try $0.insert(db) }
            var report = prepared.report
            // 옮긴 결과를 DB 에서 다시 세어 원본 수(realmWishCount)와 견준다 (GH-96 R-15)
            report.wishCount = try WishRecord.filter(prepared.wishes.map(\.id).contains(WishRecord.Columns.id)).fetchCount(db)
            try AppDatabase.setMetadata(MetadataKey.completedAt, value: Self.timestamp(now()), in: db)
            try AppDatabase.setMetadata(MetadataKey.pendingReport, value: Self.encode(report), in: db)
            return report
        }
    }

    /// 원본 Realm 에서 GRDB 에 없는 줄만 다시 넣는다 (GH-96 R-3, R-4).
    /// 토큰이 비었거나, 이미 처리한 토큰이거나, 1회 이전 전이거나, Realm 파일이 없으면 nil.
    /// 이미 있는 줄은 살아 있든 삭제 표시가 있든 건드리지 않아 업데이트 뒤의 수정·삭제가 그대로 남는다
    func reimportMissing(into database: AppDatabase, token: String) throws -> ReimportReport? {
        guard !token.isEmpty else { return nil }
        let writer = database.writer
        let isReady = try writer.read { db in
            try AppDatabase.metadataValue(MetadataKey.completedAt, in: db) != nil
                && AppDatabase.metadataValue(MetadataKey.reimportToken, in: db) != token
        }
        guard isReady, let realmFileURL, FileManager.default.fileExists(atPath: realmFileURL.path) else { return nil }

        let prepared = try prepareRecords(realmFileURL: realmFileURL, importedAt: now())
        return try writer.write { db -> ReimportReport? in
            guard try AppDatabase.metadataValue(MetadataKey.reimportToken, in: db) != token else { return nil }
            let restoredWishes = try prepared.wishes.filter { try Self.insertIfMissing($0, in: db) }
            let restoredSteps = try prepared.steps.filter { try Self.insertIfMissing($0, in: db) }
            let restoredSavings = try prepared.savings.filter { try Self.insertIfMissing($0, in: db) }
            let restoredNotifications = try prepared.notifications.filter { try Self.insertIfMissing($0, in: db) }
            let restoredRowCount = restoredSteps.count + restoredSavings.count + restoredNotifications.count
            let notifiedWishIds = Set(restoredNotifications.map(\.wishId))
            try Self.moveToTop(restoredWishes, in: db)
            try AppDatabase.setMetadata(MetadataKey.reimportToken, value: token, in: db)

            let restoredIds = restoredWishes.map(\.id)
            return ReimportReport(
                restoredWishIds: restoredIds,
                restoredRowCount: restoredRowCount,
                rescheduleWishIds: restoredIds + notifiedWishIds.subtracting(restoredIds).sorted()
            )
        }
    }

    /// 같은 id 가 없을 때만 넣는다. 넣었으면 true
    private static func insertIfMissing(_ record: some PersistableRecord, in db: Database) throws -> Bool {
        try record.insert(db, onConflict: .ignore)
        return db.changesCount > 0
    }

    /// 되돌아온 위시를 카테고리 맨 위에 둔다. 최근에 만든 위시가 가장 위 (GH-96 R-5, 작성과 같은 규칙)
    private static func moveToTop(_ restored: [WishRecord], in db: Database) throws {
        let restoredIds = Set(restored.map(\.id))
        for (category, records) in Dictionary(grouping: restored, by: \.category) {
            let minimum = try WishRecordStore.aliveWishes()
                .filter(WishRecord.Columns.category == category && !restoredIds.contains(WishRecord.Columns.id))
                .select(min(WishRecord.Columns.manualOrder), as: Double?.self)
                .fetchOne(db) ?? nil
            let top = minimum ?? 1
            let newestFirst = records.sorted { $0.createdAt > $1.createdAt }
            for (index, record) in newestFirst.enumerated() {
                try WishRecord
                    .filter(WishRecord.Columns.id == record.id)
                    .updateAll(db, WishRecord.Columns.manualOrder.set(to: top - Double(newestFirst.count - index)))
            }
        }
    }

    // MARK: - Realm → 레코드

    private struct Prepared {
        var wishes: [WishRecord] = []
        var steps: [WishStepRecord] = []
        var savings: [WishSavingRecord] = []
        var notifications: [WishNotificationRecord] = []
        var report = Report(wishCount: 0, realmWishCount: 0, reassignedIdCount: 0, rescheduleWishIds: [])
    }

    private func prepareRecords(realmFileURL: URL, importedAt: Date) throws -> Prepared {
        let realm = try Realm(configuration: LegacyRealmConfiguration.make(fileURL: realmFileURL))
        var ids = UniqueIds()
        var prepared = Prepared()

        for dto in realm.objects(WishDTO.self) {
            let wishId = ids.claim(dto._id, in: "wish")
            prepared.wishes.append(WishRecord(
                id: wishId,
                category: (Category(rawValue: dto.category) ?? .wantToDo).rawValue,
                emoji: dto.emoji,
                title: dto.title,
                date: dto.date,
                finishDate: dto.finishDate,
                targetAmount: dto.targetAmount,
                // Realm 시절 금액은 모두 원화였다 (GH-103)
                currency: "KRW",
                memo: dto.memo,
                hashtag: dto.hashtag,
                isSuccess: dto.isSuccess,
                finishNote: dto.finishNote,
                pinnedAt: dto.pinnedAt,
                link: dto.link,
                lastCheckedAt: dto.lastCheckedAt,
                placeName: dto.placeName,
                placeAddress: dto.placeAddress,
                latitude: dto.latitude,
                longitude: dto.longitude,
                photoFileName: dto.photoFileName,
                // Realm 시절에는 편지가 없었다 (GH-61)
                futureLetter: "",
                futureLetterSealedAt: nil,
                // 아래에서 카테고리별 최근 생성순으로 다시 채운다 (GH-73 R-3)
                manualOrder: 0,
                // Realm 시절에는 이어 적기가 없었다 (GH-84)
                previousWishId: nil,
                createdAt: dto.createdAt,
                updatedAt: importedAt,
                deletedAt: nil
            ))

            for step in dto.steps {
                prepared.steps.append(WishStepRecord(
                    id: ids.claim(step._id, in: "wishStep"),
                    wishId: wishId,
                    title: step.title,
                    isDone: step.isDone,
                    order: step.order,
                    updatedAt: importedAt,
                    deletedAt: nil
                ))
            }

            for saving in dto.savings {
                prepared.savings.append(WishSavingRecord(
                    id: ids.claim(saving._id, in: "wishSaving"),
                    wishId: wishId,
                    amount: saving.amount,
                    createdAt: saving.createdAt,
                    updatedAt: importedAt,
                    deletedAt: nil
                ))
            }

            var needsReschedule = false
            for (order, notification) in dto.notifications.enumerated() {
                let id = ids.claim(notification.id, in: "wishNotification")
                needsReschedule = needsReschedule || id != notification.id
                prepared.notifications.append(WishNotificationRecord(
                    id: id,
                    wishId: wishId,
                    type: (SeepNotification.NotificationType(rawValue: notification.type) ?? .targetDay).rawValue,
                    time: notification.time,
                    order: order,
                    updatedAt: importedAt,
                    deletedAt: nil
                ))
            }
            if needsReschedule {
                prepared.report.rescheduleWishIds.append(wishId)
            }
        }

        // "내가 정한 순서"는 마이그레이션 v3 과 같은 규칙: 카테고리마다 최근 생성순 1, 2, 3 … (GH-73 R-3)
        for category in Set(prepared.wishes.map(\.category)) {
            let ordered = prepared.wishes.indices
                .filter { prepared.wishes[$0].category == category }
                .sorted { prepared.wishes[$0].createdAt > prepared.wishes[$1].createdAt }
            for (position, index) in ordered.enumerated() {
                prepared.wishes[index].manualOrder = Double(position + 1)
            }
        }

        prepared.report.wishCount = prepared.wishes.count
        prepared.report.realmWishCount = realm.objects(WishDTO.self).count
        prepared.report.reassignedIdCount = ids.reassignedCount
        return prepared
    }

    /// Realm 은 `_id`에 PK 제약이 없어 같은 id 가 여럿일 수 있다. 겹치거나 빈 id 는 새 id 로 바꿔 데이터를 버리지 않는다 (R-18).
    /// 새 id 는 (테이블, 원래 id, 몇 번째로 나왔는지)로 정해지는 UUID 라, 같은 Realm 을 다시 읽어도 같은 줄은 같은 id 를 받는다.
    /// 그래야 재이전(GH-96)이 이미 옮긴 줄을 또 넣지 않는다
    private struct UniqueIds {
        private static let namespace = UUID(uuidString: "6F3A9C52-1B7E-4D2A-9E61-5C0B8F4A7D13")!
        private var claimed: [String: Set<String>] = [:]
        private var occurrences: [String: Int] = [:]
        private(set) var reassignedCount = 0

        mutating func claim(_ id: String, in table: String) -> String {
            var tableIds = claimed[table, default: []]
            defer { claimed[table] = tableIds }
            if !id.isEmpty, tableIds.insert(id).inserted {
                return id
            }
            reassignedCount += 1
            let key = "\(table)\n\(id)"
            var occurrence = occurrences[key, default: 0]
            var newId: String
            repeat {
                occurrence += 1
                newId = Self.nameBasedUUID("\(key)\n\(occurrence)")
            } while !tableIds.insert(newId).inserted
            occurrences[key] = occurrence
            return newId
        }

        /// RFC 4122 이름 기반 UUID (버전 5, SHA-1)
        private static func nameBasedUUID(_ name: String) -> String {
            var input = withUnsafeBytes(of: namespace.uuid) { Data($0) }
            input.append(Data(name.utf8))
            var bytes = Array(Insecure.SHA1.hash(data: input).prefix(16))
            bytes[6] = (bytes[6] & 0x0F) | 0x50
            bytes[8] = (bytes[8] & 0x3F) | 0x80
            let uuid = bytes.withUnsafeBytes { $0.load(as: uuid_t.self) }
            return UUID(uuid: uuid).uuidString
        }
    }

    // MARK: - Metadata 값

    static func timestamp(_ date: Date) -> String {
        String(date.timeIntervalSinceReferenceDate)
    }

    static func encode(_ report: Report) throws -> String {
        String(decoding: try JSONEncoder().encode(report), as: UTF8.self)
    }

    static func decode(_ value: String) -> Report? {
        try? JSONDecoder().decode(Report.self, from: Data(value.utf8))
    }

    /// 앱이 아직 처리하지 않은 이전 결과 (이벤트·알림 재예약 전)
    static func pendingReport(in database: AppDatabase) -> Report? {
        let value = try? database.writer.read { try AppDatabase.metadataValue(MetadataKey.pendingReport, in: $0) }
        return value.flatMap { $0 }.flatMap(decode)
    }

    static func clearPendingReport(in database: AppDatabase) {
        try? database.writer.write { try AppDatabase.setMetadata(MetadataKey.pendingReport, value: nil, in: $0) }
    }
}
