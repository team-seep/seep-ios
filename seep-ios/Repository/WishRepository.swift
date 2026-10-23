import Foundation

import GRDB

protocol WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish]
    
    func fetchNotFinishCount(category: Category) -> Int
    
    func finishWish(wish: Wish) -> Result<Wish, RepositoryError>
    
    func deleteWish(id: String)
    
    /// 단계의 완료 여부를 뒤집고, 갱신된 단계 목록(order 오름차순)을 돌려준다. 상세 화면 체크/해제용.
    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError>
    
    /// 모은 돈 기록을 추가하고, 갱신된 기록 목록(최신순)을 돌려준다 (GH-16 R-4).
    func addSaving(wishId: String, amount: Int) -> Result<[WishSaving], RepositoryError>
    
    /// 모은 돈 기록을 지우고, 갱신된 기록 목록(최신순)을 돌려준다 (GH-16 R-5).
    func deleteSaving(wishId: String, savingId: String) -> Result<[WishSaving], RepositoryError>
    
    /// 완료 소감을 저장하고, 소감이 반영된 위시를 돌려준다 (GH-25 R-3).
    func updateFinishNote(wishId: String, note: String) -> Result<Wish, RepositoryError>
    
    /// 세 카테고리 전체에서 제목·메모·해시태그에 검색어가 들어간 위시를 돌려준다. 정렬·묶음은 화면이 정한다 (GH-32 R-3).
    func searchWishes(keyword: String) -> [Wish]
    
    /// 카테고리와 무관하게 `finishDate`가 [from, to) 안인 완료 위시를 돌려준다 (GH-34 R-3).
    func fetchFinishedWishes(from: Date, to: Date) -> [Wish]
    
    /// 카테고리와 무관하게 완료한 위시 전체. 배지 계산용 (GH-35 R-3)
    func fetchAllFinishedWishes() -> [Wish]
    
    /// 홈 맨 위 고정/해제. 고정이면 지금 시각을 pinnedAt 에 넣고, 해제면 nil 로 비운다 (GH-33 R-8)
    func updatePin(wishId: String, isPinned: Bool) -> Result<Wish, RepositoryError>
    
    /// "여전히 하고 싶어요"로 점검 시각(lastCheckedAt)을 지금으로 저장하고, 반영된 위시를 돌려준다 (GH-30 R-7, R-10).
    func markChecked(wishId: String) -> Result<Wish, RepositoryError>
    
    /// 장소를 저장(nil 이면 지우기)하고, 장소가 반영된 위시를 돌려준다 (GH-31 R-4).
    func updatePlace(wishId: String, place: WishPlace?) -> Result<Wish, RepositoryError>
    
    /// 사진 파일 이름을 저장하고(빈 값이면 사진 없음), 반영된 위시를 돌려준다 (GH-36 R-9).
    func updatePhoto(wishId: String, fileName: String) -> Result<Wish, RepositoryError>
    
    /// id 로 위시 하나를 읽는다. 없으면(지워졌으면) nil. 잠금화면 위젯 링크로 상세를 열 때 쓴다 (GH-47 R-14)
    func fetchWish(id: String) -> Wish?

    /// 작성 폼에서 만든 위시를 저장하고, 저장된 위시를 돌려준다 (GH-64 P2)
    func addWish(_ wish: Wish) -> Result<Wish, RepositoryError>

    /// 수정 폼에서 바꾼 값을 저장한다. 바꾸는 필드는 예전 작성 서비스(GH-64 P2에서 삭제)와 같다
    /// (모은 돈 기록·장소·사진·완료 상태는 건드리지 않는다) (GH-64 P2)
    func updateWish(_ wish: Wish) -> Result<Wish, RepositoryError>
    
    /// 완료를 취소하고(완료일·소감도 지운다), 반영된 위시를 돌려준다. 상세 ⋯ "완료 취소하기" (GH-64 TC-605, GH-25 R-6)
    func cancelFinish(wishId: String) -> Result<Wish, RepositoryError>

    /// "미래의 나에게" 편지를 봉인한다. 이미 있으면 새 내용·새 봉인 시각으로 덮어쓴다 (GH-61 R-4)
    func sealFutureLetter(wishId: String, letter: String) -> Result<Wish, RepositoryError>

    /// 편지를 지운다. 상세 ⋯ "편지 지우기" (GH-61 R-7)
    func deleteFutureLetter(wishId: String) -> Result<Wish, RepositoryError>
}

final class WishRepositoryImpl: WishRepository {
    private let database: AppDatabase?
    private let now: () -> Date

    init(database: AppDatabase? = AppDatabase.shared, now: @escaping () -> Date = Date.init) {
        self.database = database
        self.now = now
    }

    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish] {
        var request = WishRecordStore.aliveWishes().filter(WishRecord.Columns.category == category.rawValue)
        if isOnlyFinished {
            request = request.filter(WishRecord.Columns.isSuccess == true)
        }
        return sort.sorted(read { try WishRecordStore.fetchWishes(request, in: $0) } ?? [])
    }

    func fetchNotFinishCount(category: Category) -> Int {
        let request = WishRecordStore.aliveWishes()
            .filter(WishRecord.Columns.category == category.rawValue && WishRecord.Columns.isSuccess == false)
        return read { try request.fetchCount($0) } ?? 0
    }

    func finishWish(wish: Wish) -> Result<Wish, RepositoryError> {
        let finishDate = DateUtils.now()
        return write { db, now in
            try WishRecordStore.updateWish(id: wish.id, now: now, in: db) { record in
                record.isSuccess = true
                record.finishDate = finishDate
                // 완료하면 고정을 푼다. 완료를 취소해도 돌아오지 않는다 (GH-33 R-6)
                record.pinnedAt = nil
            }
            var finishedWish = wish
            finishedWish.isSuccess = true
            finishedWish.finishDate = finishDate
            finishedWish.pinnedAt = nil
            return finishedWish
        }
    }

    func deleteWish(id: String) {
        // 줄을 지우지 않고 삭제 표시만 남긴다. 프로토콜이 결과를 돌려주지 않아 실패하면 위시가 목록에 남는다 (GH-79 R-5)
        _ = write { db, now in
            try WishRecordStore.softDeleteWish(id: id, now: now, in: db)
        }
    }

    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError> {
        return write { db, now in
            try WishRecordStore.updateStep(wishId: wishId, stepId: stepId, now: now, in: db) { $0.isDone.toggle() }
            return try WishRecordStore.aliveSteps(wishId: wishId, in: db)
                .map { WishStep(id: $0.id, title: $0.title, isDone: $0.isDone, order: $0.order) }
                .sorted { $0.order < $1.order }
        }
    }

    func addSaving(wishId: String, amount: Int) -> Result<[WishSaving], RepositoryError> {
        return write { db, now in
            try WishRecordStore.updateWish(id: wishId, now: now, in: db) { _ in }
            let saving = WishSaving(amount: amount, createdAt: DateUtils.now())
            try WishSavingRecord(saving: saving, wishId: wishId, updatedAt: now).insert(db)
            return try Self.savings(wishId: wishId, in: db)
        }
    }

    func deleteSaving(wishId: String, savingId: String) -> Result<[WishSaving], RepositoryError> {
        return write { db, now in
            try WishRecordStore.updateWish(id: wishId, now: now, in: db) { _ in }
            if var saving = try WishRecordStore.aliveSavings(wishId: wishId, in: db).first(where: { $0.id == savingId }) {
                saving.deletedAt = now
                saving.updatedAt = now
                try saving.update(db)
            }
            return try Self.savings(wishId: wishId, in: db)
        }
    }

    func updateFinishNote(wishId: String, note: String) -> Result<Wish, RepositoryError> {
        return updateAndFetch(wishId: wishId) { $0.finishNote = note }
    }

    func searchWishes(keyword: String) -> [Wish] {
        guard let keyword = WishSearchMatcher.normalize(keyword) else { return [] }
        // 해시태그 표시 이름(예: trip → 여행)까지 봐야 해서 SQL 대신 도메인 모델에서 거른다
        return (read { try WishRecordStore.fetchWishes(WishRecordStore.aliveWishes(), in: $0) } ?? [])
            .filter { WishSearchMatcher.matches(wish: $0, keyword: keyword) }
    }

    func fetchFinishedWishes(from: Date, to: Date) -> [Wish] {
        return fetchAllFinishedWishes().filter { wish in
            guard let finishDate = wish.finishDate else { return false }
            return finishDate >= from && finishDate < to
        }
    }

    func fetchAllFinishedWishes() -> [Wish] {
        let request = WishRecordStore.aliveWishes().filter(WishRecord.Columns.isSuccess == true)
        return read { try WishRecordStore.fetchWishes(request, in: $0) } ?? []
    }

    func updatePin(wishId: String, isPinned: Bool) -> Result<Wish, RepositoryError> {
        // 고정끼리 순서를 가르므로 시각까지 남긴다 (DateUtils.now()는 자정으로 잘라 쓰지 않는다)
        let pinnedAt = isPinned ? now() : nil
        return updateAndFetch(wishId: wishId) { $0.pinnedAt = pinnedAt }
    }

    func markChecked(wishId: String) -> Result<Wish, RepositoryError> {
        let checkedAt = now()
        return updateAndFetch(wishId: wishId) { $0.lastCheckedAt = checkedAt }
    }

    func updatePlace(wishId: String, place: WishPlace?) -> Result<Wish, RepositoryError> {
        return updateAndFetch(wishId: wishId) { record in
            record.placeName = place?.name ?? ""
            record.placeAddress = place?.address ?? ""
            record.latitude = place?.latitude ?? 0
            record.longitude = place?.longitude ?? 0
        }
    }

    func updatePhoto(wishId: String, fileName: String) -> Result<Wish, RepositoryError> {
        return updateAndFetch(wishId: wishId) { $0.photoFileName = fileName }
    }

    func fetchWish(id: String) -> Wish? {
        return read { try WishRecordStore.fetchWish(id: id, in: $0) } ?? nil
    }

    func cancelFinish(wishId: String) -> Result<Wish, RepositoryError> {
        return updateAndFetch(wishId: wishId) { record in
            record.isSuccess = false
            record.finishDate = nil
            // 다시 완료하면 소감을 새로 묻는다 (GH-25 R-6)
            record.finishNote = ""
        }
    }

    func sealFutureLetter(wishId: String, letter: String) -> Result<Wish, RepositoryError> {
        let sealedAt = now()
        return updateAndFetch(wishId: wishId) { record in
            record.futureLetter = letter
            record.futureLetterSealedAt = sealedAt
        }
    }

    func deleteFutureLetter(wishId: String) -> Result<Wish, RepositoryError> {
        return updateAndFetch(wishId: wishId) { record in
            record.futureLetter = ""
            record.futureLetterSealedAt = nil
        }
    }

    func addWish(_ wish: Wish) -> Result<Wish, RepositoryError> {
        return write { db, now in
            try WishRecordStore.insert(wish, now: now, in: db)
            return try Self.fetchExisting(id: wish.id, in: db)
        }
    }

    func updateWish(_ wish: Wish) -> Result<Wish, RepositoryError> {
        let checkedAt = now()
        return write { db, now in
            try WishRecordStore.updateWish(id: wish.id, now: now, in: db) { record in
                record.emoji = wish.emoji
                record.category = wish.category.rawValue
                record.title = wish.title
                record.date = wish.endDate
                record.memo = wish.memo
                record.hashtag = wish.hashtag
                // 목표 금액만 바꾸고 모은 돈 기록(savings)은 건드리지 않는다 (GH-16 R-7)
                record.targetAmount = wish.targetAmount
                // 수정 폼이 고정 여부를 정해 넘긴다. 카테고리를 바꾸면 nil 이다 (GH-33 R-9)
                record.pinnedAt = wish.pinnedAt
                // 링크는 문자열만 저장한다 (GH-29 R-7)
                record.link = wish.link
                // 수정해 저장하면 손댄 것으로 보고 잠든 위시 판정 기준을 갱신한다 (GH-30 R-2)
                record.lastCheckedAt = wish.lastCheckedAt ?? checkedAt
            }
            try WishRecordStore.replaceNotifications(wishId: wish.id, with: wish.notifications, now: now, in: db)
            try WishRecordStore.replaceSteps(wishId: wish.id, with: wish.steps, now: now, in: db)
            return try Self.fetchExisting(id: wish.id, in: db)
        }
    }

    // MARK: - Private

    private func read<T>(_ block: (Database) throws -> T) -> T? {
        guard let database else { return nil }
        return try? database.writer.read(block)
    }

    private func write<T>(_ block: (Database, Date) throws -> T) -> Result<T, RepositoryError> {
        guard let database else { return .failure(.noDatabase) }
        let now = now()
        do {
            return .success(try database.writer.write { try block($0, now) })
        } catch {
            return .failure(RepositoryError(error))
        }
    }

    private func updateAndFetch(wishId: String, _ change: @escaping (inout WishRecord) -> Void) -> Result<Wish, RepositoryError> {
        return write { db, now in
            try WishRecordStore.updateWish(id: wishId, now: now, in: db, change)
            return try Self.fetchExisting(id: wishId, in: db)
        }
    }

    private static func fetchExisting(id: String, in db: Database) throws -> Wish {
        guard let wish = try WishRecordStore.fetchWish(id: id, in: db) else {
            throw WishRecordStore.StoreError.targetNotFound
        }
        return wish
    }

    private static func savings(wishId: String, in db: Database) throws -> [WishSaving] {
        WishSaving.latestFirst(
            try WishRecordStore.aliveSavings(wishId: wishId, in: db)
                .map { WishSaving(id: $0.id, amount: $0.amount, createdAt: $0.createdAt) }
        )
    }
}
