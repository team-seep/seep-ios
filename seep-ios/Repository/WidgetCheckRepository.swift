import Foundation

import GRDB

/// 체크 위젯(GH-48)이 쓰는 저장소. 앱·위젯 두 타깃에 들어간다 (R-6).
/// `WishRepository`는 SwiftGen·Then 에 묶인 타입을 써서 위젯 타깃에 넣을 수 없어 따로 둔다.
/// 앱·위젯이 같은 App Group DB(`AppDatabase.shared`)를 연다 (GH-79).
protocol WidgetCheckRepository {
    /// 위젯 목록: 미완료 위시 + 오늘 위젯에서 완료한 위시를 `Wish.deadlineOrder`로 정렬해 `limit`개 (R-1, R-4)
    func fetchCheckWidgetWishes(limit: Int) -> [Wish]

    func fetchWish(id: String) -> Wish?

    /// 단계 하나를 완료로 (R-3)
    func checkStep(wishId: String, stepId: String) -> Result<Wish, RepositoryError>

    /// 남은 마지막 단계(있으면)까지 완료하고 위시를 완료로. 앱의 `finishWish`와 같은 규칙 (R-3, R-7)
    func finishWish(wishId: String, lastStepId: String?) -> Result<Wish, RepositoryError>

    /// 위젯에서 완료한 위시의 완료를 취소. 단계는 되돌리지 않는다 (R-4)
    func unfinishWish(wishId: String) -> Result<Wish, RepositoryError>
}

final class WidgetCheckRepositoryImpl: WidgetCheckRepository {
    private let database: AppDatabase?
    private let store: WidgetCheckStore
    private let now: () -> Date
    private let calendar: Calendar

    init(
        database: AppDatabase? = AppDatabase.shared,
        store: WidgetCheckStore = .shared,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.database = database
        self.store = store
        self.now = now
        self.calendar = calendar
    }

    func fetchCheckWidgetWishes(limit: Int) -> [Wish] {
        guard let database,
              let wishes = try? database.writer.read({ try WishRecordStore.fetchWishes(WishRecordStore.aliveWishes(), in: $0) })
        else { return [] }
        let doneIds = store.doneWishIds(now: now(), calendar: calendar)
        let visible = wishes
            .filter { !$0.isSuccess || doneIds.contains($0.id) }
            .sorted(by: Wish.deadlineOrder)
        return Array(visible.prefix(limit))
    }

    func fetchWish(id: String) -> Wish? {
        guard let database else { return nil }
        return (try? database.writer.read { try WishRecordStore.fetchWish(id: id, in: $0) }) ?? nil
    }

    func checkStep(wishId: String, stepId: String) -> Result<Wish, RepositoryError> {
        let result = write(wishId: wishId) { db, now in
            try WishRecordStore.updateStep(wishId: wishId, stepId: stepId, now: now, in: db) { $0.isDone = true }
        }
        if case .success = result {
            store.recordStepCheck(at: now())
        }
        return result
    }

    func finishWish(wishId: String, lastStepId: String?) -> Result<Wish, RepositoryError> {
        let finishedAt = now()
        let result = write(wishId: wishId) { db, now in
            if let lastStepId {
                try WishRecordStore.updateStep(wishId: wishId, stepId: lastStepId, now: now, in: db) { $0.isDone = true }
            }
            try WishRecordStore.updateWish(id: wishId, now: now, in: db) { record in
                record.isSuccess = true
                // 앱의 완료와 같게 날짜만 남긴다 (DateUtils.now() 규칙)
                record.finishDate = self.calendar.startOfDay(for: finishedAt)
                // 완료하면 고정을 푼다 (GH-33 R-6)
                record.pinnedAt = nil
            }
        }
        if case .success = result {
            store.recordFinish(wishId: wishId, at: finishedAt)
        }
        return result
    }

    func unfinishWish(wishId: String) -> Result<Wish, RepositoryError> {
        let result = write(wishId: wishId) { db, now in
            try WishRecordStore.updateWish(id: wishId, now: now, in: db) { record in
                record.isSuccess = false
                record.finishDate = nil
                // 다시 완료하면 소감을 새로 묻는다 (앱의 완료 취소와 같은 규칙, GH-25 R-6)
                record.finishNote = ""
            }
        }
        if case .success = result {
            store.recordUnfinish(wishId: wishId, at: now())
        }
        return result
    }

    private func write(wishId: String, update: (Database, Date) throws -> Void) -> Result<Wish, RepositoryError> {
        guard let database else { return .failure(.noDatabase) }
        let now = now()
        do {
            return .success(try database.writer.write { db in
                try update(db, now)
                guard let wish = try WishRecordStore.fetchWish(id: wishId, in: db) else {
                    throw WishRecordStore.StoreError.targetNotFound
                }
                return wish
            })
        } catch {
            return .failure(RepositoryError(error))
        }
    }
}
