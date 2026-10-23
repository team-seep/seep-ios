import Foundation

import GRDB
import RealmSwift

/// Realm → GRDB 1회 이전 (GH-79 R-17~R-19, R-23).
/// 앱·위젯 중 먼저 DB 를 여는 쪽이 한다. 업데이트 뒤 앱보다 위젯이 먼저 갱신돼도 기존 위시가 보이게 하기 위해서다 (TC-11).
struct LegacyRealmImporter {
    /// 이전 결과. 이벤트(`db_migration`)와 알림 재예약은 앱이 다음 실행에서 처리한다 (위젯은 GA·알림 매니저를 못 쓴다)
    struct Report: Codable, Equatable {
        var wishCount: Int
        /// 이미 옮긴 id 와 겹치거나 비어 있어 새 UUID 를 붙인 레코드 수 (R-18)
        var reassignedIdCount: Int
        /// 새 id 를 받은 알림이 있는 위시. 새 id 로 다시 예약해야 한다 (R-23)
        var rescheduleWishIds: [String]
    }

    enum MetadataKey {
        static let completedAt = "legacyRealmImport.completedAt"
        static let pendingReport = "legacyRealmImport.pendingReport"
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
            try AppDatabase.setMetadata(MetadataKey.completedAt, value: Self.timestamp(now()), in: db)
            try AppDatabase.setMetadata(MetadataKey.pendingReport, value: Self.encode(prepared.report), in: db)
            return prepared.report
        }
    }

    // MARK: - Realm → 레코드

    private struct Prepared {
        var wishes: [WishRecord] = []
        var steps: [WishStepRecord] = []
        var savings: [WishSavingRecord] = []
        var notifications: [WishNotificationRecord] = []
        var report = Report(wishCount: 0, reassignedIdCount: 0, rescheduleWishIds: [])
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
        prepared.report.reassignedIdCount = ids.reassignedCount
        return prepared
    }

    /// Realm 은 `_id`에 PK 제약이 없어 같은 id 가 여럿일 수 있다. 겹치거나 빈 id 는 새 UUID 로 바꿔 데이터를 버리지 않는다 (R-18)
    private struct UniqueIds {
        private var claimed: [String: Set<String>] = [:]
        private(set) var reassignedCount = 0

        mutating func claim(_ id: String, in table: String) -> String {
            var tableIds = claimed[table, default: []]
            defer { claimed[table] = tableIds }
            if !id.isEmpty, tableIds.insert(id).inserted {
                return id
            }
            reassignedCount += 1
            let newId = UUID().uuidString
            tableIds.insert(newId)
            return newId
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
