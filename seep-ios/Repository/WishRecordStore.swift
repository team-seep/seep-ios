import Foundation

import GRDB

/// 위시와 하위 레코드(단계·저금·알림·일지·태그)를 한 묶음으로 읽고 쓴다. 앱·위젯 Repository 가 같이 쓴다 (GH-79 R-13).
/// - 읽기는 삭제 표시가 없는 줄만 본다 (R-6)
/// - 쓰기는 바뀐 줄과 부모 위시의 `updatedAt`을 갱신하고, 지우기는 `deletedAt`만 남긴다 (R-4, R-5)
enum WishRecordStore {
    enum StoreError: Error {
        case targetNotFound
    }

    // MARK: - 읽기

    static func aliveWishes() -> QueryInterfaceRequest<WishRecord> {
        WishRecord.filter(WishRecord.Columns.deletedAt == nil)
    }

    static func fetchWishes(_ request: QueryInterfaceRequest<WishRecord>, in db: Database) throws -> [Wish] {
        let records = try request.fetchAll(db)
        guard !records.isEmpty else { return [] }
        let ids = records.map(\.id)

        let steps = try Dictionary(
            grouping: WishStepRecord
                .filter(ids.contains(WishStepRecord.Columns.wishId) && WishStepRecord.Columns.deletedAt == nil)
                .fetchAll(db),
            by: \.wishId
        )
        let savings = try Dictionary(
            grouping: WishSavingRecord
                .filter(ids.contains(WishSavingRecord.Columns.wishId) && WishSavingRecord.Columns.deletedAt == nil)
                .fetchAll(db),
            by: \.wishId
        )
        let notifications = try Dictionary(
            grouping: WishNotificationRecord
                .filter(ids.contains(WishNotificationRecord.Columns.wishId) && WishNotificationRecord.Columns.deletedAt == nil)
                .fetchAll(db),
            by: \.wishId
        )
        let journals = try Dictionary(
            grouping: WishJournalRecord
                .filter(ids.contains(WishJournalRecord.Columns.wishId) && WishJournalRecord.Columns.deletedAt == nil)
                .fetchAll(db),
            by: \.wishId
        )
        let tags = try Dictionary(
            grouping: WishTagRecord
                .filter(ids.contains(WishTagRecord.Columns.wishId) && WishTagRecord.Columns.deletedAt == nil)
                .fetchAll(db),
            by: \.wishId
        )

        return records.map { record in
            Wish(
                record: record,
                steps: steps[record.id] ?? [],
                savings: savings[record.id] ?? [],
                notifications: notifications[record.id] ?? [],
                journals: journals[record.id] ?? [],
                tags: tags[record.id] ?? []
            )
        }
    }

    static func fetchWish(id: String, in db: Database) throws -> Wish? {
        try fetchWishes(aliveWishes().filter(WishRecord.Columns.id == id), in: db).first
    }

    // MARK: - 쓰기

    static func insert(_ wish: Wish, now: Date, in db: Database) throws {
        try WishRecord(wish: wish, updatedAt: now).insert(db)
        for step in wish.steps {
            try WishStepRecord(step: step, wishId: wish.id, updatedAt: now).insert(db)
        }
        for saving in wish.savings {
            try WishSavingRecord(saving: saving, wishId: wish.id, updatedAt: now).insert(db)
        }
        for (order, notification) in wish.notifications.enumerated() {
            try WishNotificationRecord(notification: notification, wishId: wish.id, order: order, updatedAt: now).insert(db)
        }
        for journal in wish.journals {
            try WishJournalRecord(journal: journal, wishId: wish.id, updatedAt: now).insert(db)
        }
        for (order, name) in wish.tags.enumerated() {
            try WishTagRecord(name: name, wishId: wish.id, order: order, now: now).insert(db)
        }
    }

    /// 살아 있는 위시 한 줄을 바꾸고 `updatedAt`을 갱신한다. 없으면(지웠으면) `targetNotFound`
    @discardableResult
    static func updateWish(id: String, now: Date, in db: Database, _ change: (inout WishRecord) -> Void) throws -> WishRecord {
        guard var record = try aliveWishes().filter(WishRecord.Columns.id == id).fetchOne(db) else {
            throw StoreError.targetNotFound
        }
        change(&record)
        record.updatedAt = now
        try record.update(db)
        return record
    }

    /// 위시와 하위 레코드에 삭제 표시를 한다 (R-5)
    static func softDeleteWish(id: String, now: Date, in db: Database) throws {
        try updateWish(id: id, now: now, in: db) { record in
            record.deletedAt = now
            // 지운 위시의 근처 알림이 다른 기기에서 다시 걸리지 않게 끈다 (GH-126 R-7)
            record.nearbyAlertOn = false
        }
        let assignments = [Column("deletedAt").set(to: now.timeIntervalSinceReferenceDate), Column("updatedAt").set(to: now.timeIntervalSinceReferenceDate)]
        try WishStepRecord.filter(WishStepRecord.Columns.wishId == id && WishStepRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishSavingRecord.filter(WishSavingRecord.Columns.wishId == id && WishSavingRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishNotificationRecord.filter(WishNotificationRecord.Columns.wishId == id && WishNotificationRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishJournalRecord.filter(WishJournalRecord.Columns.wishId == id && WishJournalRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishTagRecord.filter(WishTagRecord.Columns.wishId == id && WishTagRecord.Columns.deletedAt == nil).updateAll(db, assignments)
    }

    static func aliveSteps(wishId: String, in db: Database) throws -> [WishStepRecord] {
        try WishStepRecord
            .filter(WishStepRecord.Columns.wishId == wishId && WishStepRecord.Columns.deletedAt == nil)
            .fetchAll(db)
    }

    static func aliveJournals(wishId: String, in db: Database) throws -> [WishJournalRecord] {
        try WishJournalRecord
            .filter(WishJournalRecord.Columns.wishId == wishId && WishJournalRecord.Columns.deletedAt == nil)
            .fetchAll(db)
    }

    static func aliveSavings(wishId: String, in db: Database) throws -> [WishSavingRecord] {
        try WishSavingRecord
            .filter(WishSavingRecord.Columns.wishId == wishId && WishSavingRecord.Columns.deletedAt == nil)
            .fetchAll(db)
    }

    /// 단계 하나를 바꾸고 부모 위시의 `updatedAt`도 갱신한다. 단계가 없으면 아무것도 하지 않는다
    static func updateStep(wishId: String, stepId: String, now: Date, in db: Database, _ change: (inout WishStepRecord) -> Void) throws {
        try updateWish(id: wishId, now: now, in: db) { _ in }
        guard var step = try aliveSteps(wishId: wishId, in: db).first(where: { $0.id == stepId }) else { return }
        change(&step)
        step.updatedAt = now
        try step.update(db)
    }

    /// 수정 폼의 단계로 바꾼다. 빠진 단계는 삭제 표시, 남은·새 단계는 upsert (GH-5 R-19: 남은 단계는 id·isDone 을 그대로 가진다)
    static func replaceSteps(wishId: String, with steps: [WishStep], now: Date, in db: Database) throws {
        let keepIds = Set(steps.map(\.id))
        for old in try aliveSteps(wishId: wishId, in: db) where !keepIds.contains(old.id) {
            var deleted = old
            deleted.deletedAt = now
            deleted.updatedAt = now
            try deleted.update(db)
        }
        let aliveById = Dictionary(try aliveSteps(wishId: wishId, in: db).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for step in steps {
            // 남은 단계는 체크한 시각을 지킨다. 폼이 체크 여부를 바꿨으면 그에 맞춘다 (GH-146 TC-15)
            var record = WishStepRecord(step: step, wishId: wishId, updatedAt: now, doneAt: aliveById[step.id]?.doneAt)
            if let old = aliveById[step.id], old.isDone != step.isDone {
                record.isDone = old.isDone
                record.setDone(step.isDone, at: now)
            }
            try record.upsert(db)
        }
    }

    /// 수정 문서의 태그로 바꾼다 (GH-136). 이름으로 맞춰 남은 태그는 id·createdAt 을 그대로 두고 순서만 고치고,
    /// 빠진 태그는 삭제 표시, 새 태그만 새 줄로 넣는다 — 다른 기기와 동기화할 때 같은 태그가 새 줄로 바뀌지 않게
    static func replaceTags(wishId: String, with names: [String], now: Date, in db: Database) throws {
        let alive = try WishTagRecord
            .filter(WishTagRecord.Columns.wishId == wishId && WishTagRecord.Columns.deletedAt == nil)
            .fetchAll(db)
        var keptByName: [String: WishTagRecord] = [:]
        for old in alive {
            if names.contains(old.name), keptByName[old.name] == nil {
                keptByName[old.name] = old
            } else {
                var deleted = old
                deleted.deletedAt = now
                deleted.updatedAt = now
                try deleted.update(db)
            }
        }
        for (order, name) in names.enumerated() {
            if var kept = keptByName[name] {
                guard kept.order != order else { continue }
                kept.order = order
                kept.updatedAt = now
                try kept.update(db)
            } else {
                try WishTagRecord(name: name, wishId: wishId, order: order, now: now).insert(db)
            }
        }
    }

    /// 살아 있는 위시에 붙은 태그 이름, 최근에 쓴 것부터 하나씩. 직접 입력 태그 추천용 (GH-136)
    static func recentTagNames(in db: Database) throws -> [String] {
        try String.fetchAll(db, sql: """
            SELECT wishTag.name FROM wishTag
            JOIN wish ON wish.id = wishTag.wishId
            WHERE wishTag.deletedAt IS NULL AND wish.deletedAt IS NULL AND TRIM(wishTag.name) != ''
            GROUP BY wishTag.name
            ORDER BY MAX(wishTag.updatedAt) DESC
            """)
    }

    /// 수정 폼의 알림으로 바꾼다. 알림 id 는 예약 identifier 라 그대로 유지한다
    static func replaceNotifications(wishId: String, with notifications: [SeepNotification], now: Date, in db: Database) throws {
        let keepIds = Set(notifications.map(\.id))
        let alive = try WishNotificationRecord
            .filter(WishNotificationRecord.Columns.wishId == wishId && WishNotificationRecord.Columns.deletedAt == nil)
            .fetchAll(db)
        for old in alive where !keepIds.contains(old.id) {
            var deleted = old
            deleted.deletedAt = now
            deleted.updatedAt = now
            try deleted.update(db)
        }
        for (order, notification) in notifications.enumerated() {
            try WishNotificationRecord(notification: notification, wishId: wishId, order: order, updatedAt: now).upsert(db)
        }
    }
}

extension RepositoryError {
    /// 저장소 쓰기에서 난 오류를 화면에 돌려줄 오류로 바꾼다
    init(_ error: Error) {
        if case WishRecordStore.StoreError.targetNotFound = error {
            self = .targetNotFound
        } else {
            self = .writeFailed
        }
    }
}
