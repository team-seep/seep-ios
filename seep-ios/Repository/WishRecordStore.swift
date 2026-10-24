import Foundation

import GRDB

/// 위시와 하위 레코드(단계·저금·알림)를 한 묶음으로 읽고 쓴다. 앱·위젯 Repository 가 같이 쓴다 (GH-79 R-13).
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

        return records.map { record in
            Wish(
                record: record,
                steps: steps[record.id] ?? [],
                savings: savings[record.id] ?? [],
                notifications: notifications[record.id] ?? []
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
        try updateWish(id: id, now: now, in: db) { $0.deletedAt = now }
        let assignments = [Column("deletedAt").set(to: now.timeIntervalSinceReferenceDate), Column("updatedAt").set(to: now.timeIntervalSinceReferenceDate)]
        try WishStepRecord.filter(WishStepRecord.Columns.wishId == id && WishStepRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishSavingRecord.filter(WishSavingRecord.Columns.wishId == id && WishSavingRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishNotificationRecord.filter(WishNotificationRecord.Columns.wishId == id && WishNotificationRecord.Columns.deletedAt == nil).updateAll(db, assignments)
    }

    static func aliveSteps(wishId: String, in db: Database) throws -> [WishStepRecord] {
        try WishStepRecord
            .filter(WishStepRecord.Columns.wishId == wishId && WishStepRecord.Columns.deletedAt == nil)
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
        for step in steps {
            try WishStepRecord(step: step, wishId: wishId, updatedAt: now).upsert(db)
        }
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
