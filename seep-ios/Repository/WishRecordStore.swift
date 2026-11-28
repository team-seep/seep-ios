import Foundation

import GRDB

/// 위시와 하위 레코드(단계·저금·알림·일지·태그·함께할 사람)를 한 묶음으로 읽고 쓴다. 앱·위젯 Repository 가 같이 쓴다 (GH-79 R-13).
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
        let companions = try Dictionary(
            grouping: WishCompanionRecord
                .filter(ids.contains(WishCompanionRecord.Columns.wishId) && WishCompanionRecord.Columns.deletedAt == nil)
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
                tags: tags[record.id] ?? [],
                companions: companions[record.id] ?? []
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
        for (order, companion) in try resolvedCompanions(wish.companions, in: db).enumerated() {
            try WishCompanionRecord(companion: companion, wishId: wish.id, order: order, now: now).insert(db)
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
        try WishJournalRecord.filter(WishJournalRecord.Columns.wishId == id && WishJournalRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishTagRecord.filter(WishTagRecord.Columns.wishId == id && WishTagRecord.Columns.deletedAt == nil).updateAll(db, assignments)
        try WishCompanionRecord.filter(WishCompanionRecord.Columns.wishId == id && WishCompanionRecord.Columns.deletedAt == nil).updateAll(db, assignments)
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

    /// 수정 문서의 함께할 사람으로 바꾼다 (GH-122 R-8). `personId`로 맞춰 남은 사람은 줄 id 를 그대로 두고 이름·순서만 고치고,
    /// 빠진 사람은 삭제 표시, 새 사람만 새 줄로 넣는다 — 태그처럼 동기화할 때 같은 사람이 새 줄로 바뀌지 않게
    static func replaceCompanions(wishId: String, with companions: [WishCompanion], now: Date, in db: Database) throws {
        let companions = try resolvedCompanions(companions, in: db)
        let alive = try WishCompanionRecord
            .filter(WishCompanionRecord.Columns.wishId == wishId && WishCompanionRecord.Columns.deletedAt == nil)
            .fetchAll(db)
        let keepIds = Set(companions.map(\.personId))
        var kept: [String: WishCompanionRecord] = [:]
        for old in alive {
            if keepIds.contains(old.personId), kept[old.personId] == nil {
                kept[old.personId] = old
            } else {
                var deleted = old
                deleted.deletedAt = now
                deleted.updatedAt = now
                try deleted.update(db)
            }
        }
        for (order, companion) in companions.enumerated() {
            if var record = kept[companion.personId] {
                guard record.order != order || record.name != companion.name else { continue }
                record.order = order
                record.name = companion.name
                record.updatedAt = now
                try record.update(db)
            } else {
                try WishCompanionRecord(companion: companion, wishId: wishId, order: order, now: now).insert(db)
            }
        }
    }

    /// 살아 있는 위시에 붙은 사람, 최근에 쓴 사람부터 한 명씩(이름은 그 사람의 가장 최근 이름). "전에 적은 사람"용 (GH-122 R-3)
    static func recentCompanions(in db: Database) throws -> [WishCompanion] {
        var seen: Set<String> = []
        return try aliveCompanionRows(in: db).compactMap { row in
            guard seen.insert(row.personId).inserted else { return nil }
            return WishCompanion(personId: row.personId, name: row.name)
        }
    }

    /// 그 사람이 붙은 살아 있는 위시 id (GH-122 R-5)
    static func wishIds(personId: String, in db: Database) throws -> [String] {
        try String.fetchAll(db, sql: """
            SELECT DISTINCT wishCompanion.wishId FROM wishCompanion
            JOIN wish ON wish.id = wishCompanion.wishId
            WHERE wishCompanion.personId = ? AND wishCompanion.deletedAt IS NULL AND wish.deletedAt IS NULL
            """, arguments: [personId])
    }

    /// 저장할 사람 목록을 다듬는다 (R-2, R-11): 이름을 정리하고, 처음 보는 `personId`인데 이름이 기존 사람과 같으면 그 사람의 id 를 쓰고,
    /// 같은 사람은 한 번만, 최대 인원까지만 둔다. 화면이 들고 있던 목록이 오래돼도(다른 기기에서 같은 사람을 먼저 적음) 사람이 둘로 갈리지 않게 한다
    static func resolvedCompanions(_ companions: [WishCompanion], in db: Database) throws -> [WishCompanion] {
        guard !companions.isEmpty else { return [] }
        let known = try aliveCompanionRows(in: db)
        let knownIds = Set(known.map(\.personId))
        var idByKey: [String: String] = [:]
        for row in known where idByKey[WishCompanion.matchKey(row.name)] == nil {
            idByKey[WishCompanion.matchKey(row.name)] = row.personId
        }
        var result: [WishCompanion] = []
        for companion in companions {
            guard let name = WishCompanion.cleanedName(companion.name) else { continue }
            let key = WishCompanion.matchKey(name)
            let personId = knownIds.contains(companion.personId) ? companion.personId : idByKey[key] ?? companion.personId
            // 같은 사람(id)이나 같은 이름은 한 번만 (R-2)
            guard !result.contains(where: { $0.personId == personId || WishCompanion.matchKey($0.name) == key }),
                  result.count < WishCompanion.maxCount else { continue }
            idByKey[key] = idByKey[key] ?? personId
            result.append(WishCompanion(personId: personId, name: name))
        }
        return result
    }

    /// 살아 있는 위시에 붙은 사람 줄, 최근에 고친 것부터
    private static func aliveCompanionRows(in db: Database) throws -> [(personId: String, name: String)] {
        try Row.fetchAll(db, sql: """
            SELECT wishCompanion.personId, wishCompanion.name FROM wishCompanion
            JOIN wish ON wish.id = wishCompanion.wishId
            WHERE wishCompanion.deletedAt IS NULL AND wish.deletedAt IS NULL AND TRIM(wishCompanion.name) != ''
            ORDER BY wishCompanion.updatedAt DESC, wishCompanion.createdAt DESC
            """).map { (personId: $0["personId"], name: $0["name"]) }
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
