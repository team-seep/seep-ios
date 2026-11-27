import Foundation

import GRDB

/// 기간 안의 "싶에 다가간 행동"을 레코드에서 모은다 (GH-146 R-2).
/// 살아 있는 위시와 그 위시의 살아 있는 하위 줄만 센다 — 지운 위시의 저금·일지·단계는 빠진다 (TC-4)
enum WishActivityQuery {
    /// - Returns: [from, to) 안의 행동. 순서는 정하지 않는다
    static func fetch(from: Date, to: Date, in db: Database) throws -> [WishActivity] {
        let lower = from.timeIntervalSinceReferenceDate
        let upper = to.timeIntervalSinceReferenceDate
        func isInRange(_ date: Date?) -> Bool {
            guard let date else { return false }
            let value = date.timeIntervalSinceReferenceDate
            return value >= lower && value < upper
        }

        let wishes = try WishRecordStore.aliveWishes().fetchAll(db)
        let wishById = Dictionary(wishes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var activities: [WishActivity] = []

        func append(_ wish: WishRecord, kind: WishActivity.Kind, rowId: String, date: Date) {
            activities.append(WishActivity(
                id: "\(kind.idPrefix)-\(rowId)",
                wishId: wish.id,
                emoji: wish.emoji,
                wishTitle: wish.title,
                isWishFinished: wish.isSuccess,
                kind: kind,
                date: date
            ))
        }

        for wish in wishes {
            if isInRange(wish.createdAt) {
                append(wish, kind: .added, rowId: wish.id, date: wish.createdAt)
            }
            // 완료를 취소하면 finishDate 가 지워져 빠진다 (TC-3)
            if wish.isSuccess, let finishDate = wish.finishDate, isInRange(finishDate) {
                append(wish, kind: .finished, rowId: wish.id, date: finishDate)
            }
        }

        let doneAt = Column("doneAt")
        let steps = try WishStepRecord
            .filter(WishStepRecord.Columns.deletedAt == nil && Column("isDone") == true)
            .filter(doneAt >= lower && doneAt < upper)
            .fetchAll(db)
        for step in steps {
            guard let wish = wishById[step.wishId], let date = step.doneAt else { continue }
            append(wish, kind: .stepDone(stepTitle: step.title), rowId: step.id, date: date)
        }

        let createdAt = Column("createdAt")
        let savings = try WishSavingRecord
            .filter(WishSavingRecord.Columns.deletedAt == nil && createdAt >= lower && createdAt < upper)
            .fetchAll(db)
        for saving in savings {
            guard let wish = wishById[saving.wishId] else { continue }
            append(wish, kind: .saving(amount: saving.amount, currency: wish.currency), rowId: saving.id, date: saving.createdAt)
        }

        let journals = try WishJournalRecord
            .filter(WishJournalRecord.Columns.deletedAt == nil && createdAt >= lower && createdAt < upper)
            .fetchAll(db)
        for journal in journals {
            guard let wish = wishById[journal.wishId] else { continue }
            append(wish, kind: .journal, rowId: journal.id, date: journal.createdAt)
        }

        return activities
    }
}

private extension WishActivity.Kind {
    var idPrefix: String {
        switch self {
        case .added: return "added"
        case .stepDone: return "step"
        case .saving: return "saving"
        case .journal: return "journal"
        case .finished: return "finished"
        }
    }
}
