import Foundation

import GRDB

protocol WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish]
    
    func fetchNotFinishCount(category: Category) -> Int
    
    func finishWish(wish: Wish) -> Result<Wish, RepositoryError>
    
    func deleteWish(id: String)

    /// 여러 위시를 한 트랜잭션으로 삭제 표시한다. 하나라도 실패하면 아무것도 지우지 않는다 (GH-86 R-4)
    func deleteWishes(ids: [String]) -> Result<Void, RepositoryError>
    
    /// 단계의 완료 여부를 뒤집고, 갱신된 단계 목록(order 오름차순)을 돌려준다. 상세 화면 체크/해제용.
    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError>
    
    /// 모은 돈 기록을 추가하고, 갱신된 기록 목록(최신순)을 돌려준다 (GH-16 R-4).
    func addSaving(wishId: String, amount: Int) -> Result<[WishSaving], RepositoryError>
    
    /// 모은 돈 기록을 지우고, 갱신된 기록 목록(최신순)을 돌려준다 (GH-16 R-5).
    func deleteSaving(wishId: String, savingId: String) -> Result<[WishSaving], RepositoryError>
    
    /// 일지 한 줄을 남기고, 갱신된 일지 목록(최신순)을 돌려준다. 손댄 것으로 보고 잠든 위시 판정 기준도 갱신한다 (GH-95 R-2, R-6).
    func addJournal(wishId: String, text: String) -> Result<[WishJournal], RepositoryError>

    /// 일지 한 줄에 삭제 표시를 하고, 갱신된 일지 목록(최신순)을 돌려준다 (GH-95 R-2, R-7).
    func deleteJournal(wishId: String, journalId: String) -> Result<[WishJournal], RepositoryError>

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

    /// 위시가 이어진 싶(앞·다음)을 읽는다. 지금 위시가 없으면(지워졌으면) nil (GH-84 R-4, R-6, R-7)
    func fetchWishChain(wishId: String) -> WishChain?

    /// 작성 폼에서 만든 위시를 저장하고, 저장된 위시를 돌려준다 (GH-64 P2)
    func addWish(_ wish: Wish) -> Result<Wish, RepositoryError>

    /// 수정 폼에서 바꾼 값을 저장한다. 바꾸는 필드는 예전 작성 서비스(GH-64 P2에서 삭제)와 같다
    /// (모은 돈 기록·장소·완료 상태는 건드리지 않는다) (GH-64 P2). 사진·편지는 수정 문서 블록 값으로 저장한다 (GH-61 R-11)
    func updateWish(_ wish: Wish) -> Result<Wish, RepositoryError>
    
    /// 완료를 취소하고(완료일·소감도 지운다), 반영된 위시를 돌려준다. 상세 ⋯ "완료 취소하기" (GH-64 TC-605, GH-25 R-6)
    func cancelFinish(wishId: String) -> Result<Wish, RepositoryError>

    /// "내가 정한 순서"에서 위시를 옮긴다. `orderedIds`는 옮긴 뒤 화면의 순서(고정 위시 제외).
    /// 보통은 앞뒤 값의 중간값으로 옮긴 위시 1건만 바꾸고, 간격이 너무 좁으면 그 목록을 1, 2, 3 … 으로 다시 매긴다 (GH-73 R-7)
    func moveWish(wishId: String, orderedIds: [String]) -> Result<Void, RepositoryError>

    /// DB 가 바뀔 때마다(어느 화면이 썼든) 메인 스레드에서 알린다. 돌려받은 값을 버리거나 `cancel()`하면 멈춘다.
    /// 아이패드에서 목록과 상세가 함께 보일 때 상세에서 바꾼 내용을 목록에 반영한다 (GH-99 TC-4)
    func observeChanges(_ onChange: @escaping () -> Void) -> WishChangeObservation?
}

/// `observeChanges` 구독. GRDB 타입을 화면 쪽에 드러내지 않으려고 감싼다
protocol WishChangeObservation: AnyObject {
    func cancel()
}

extension AnyDatabaseCancellable: WishChangeObservation {}

final class WishRepositoryImpl: WishRepository {
    private let database: AppDatabase?
    private let now: () -> Date

    init(database: AppDatabase? = AppDatabase.shared, now: @escaping () -> Date = Date.init) {
        self.database = database
        self.now = now
    }

    func observeChanges(_ onChange: @escaping () -> Void) -> WishChangeObservation? {
        guard let database else { return nil }
        let observation = DatabaseRegionObservation(tracking: .fullDatabase)
        return observation.start(
            in: database.writer,
            onError: { _ in },
            onChange: { _ in DispatchQueue.main.async(execute: onChange) }
        )
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

    func deleteWishes(ids: [String]) -> Result<Void, RepositoryError> {
        return write { db, now in
            for id in ids {
                try WishRecordStore.softDeleteWish(id: id, now: now, in: db)
            }
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

    func addJournal(wishId: String, text: String) -> Result<[WishJournal], RepositoryError> {
        return write { db, now in
            try WishRecordStore.updateWish(id: wishId, now: now, in: db) { $0.lastCheckedAt = now }
            let journal = WishJournal(text: text, createdAt: now)
            try WishJournalRecord(journal: journal, wishId: wishId, updatedAt: now).insert(db)
            return try Self.journals(wishId: wishId, in: db)
        }
    }

    func deleteJournal(wishId: String, journalId: String) -> Result<[WishJournal], RepositoryError> {
        return write { db, now in
            try WishRecordStore.updateWish(id: wishId, now: now, in: db) { _ in }
            if var journal = try WishRecordStore.aliveJournals(wishId: wishId, in: db).first(where: { $0.id == journalId }) {
                journal.deletedAt = now
                journal.updatedAt = now
                try journal.update(db)
            }
            return try Self.journals(wishId: wishId, in: db)
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

    func fetchWishChain(wishId: String) -> WishChain? {
        // 삭제한 위시를 건너뛰어 잇기 위해 지운 줄까지 읽는다. id·앞 위시 id 만 쓰므로 표가 커도 가볍다
        return read { db in
            WishChain(records: try WishRecord.fetchAll(db), currentId: wishId)
        } ?? nil
    }

    func cancelFinish(wishId: String) -> Result<Wish, RepositoryError> {
        return updateAndFetch(wishId: wishId) { record in
            record.isSuccess = false
            record.finishDate = nil
            // 다시 완료하면 소감을 새로 묻는다 (GH-25 R-6)
            record.finishNote = ""
        }
    }

    func moveWish(wishId: String, orderedIds: [String]) -> Result<Void, RepositoryError> {
        return write { db, now in
            guard let index = orderedIds.firstIndex(of: wishId) else {
                throw WishRecordStore.StoreError.targetNotFound
            }
            let records = try WishRecordStore.aliveWishes()
                .filter(orderedIds.contains(WishRecord.Columns.id))
                .fetchAll(db)
            let orders = Dictionary(records.map { ($0.id, $0.manualOrder) }, uniquingKeysWith: { first, _ in first })
            let previous = index > 0 ? orders[orderedIds[index - 1]] : nil
            let next = index + 1 < orderedIds.count ? orders[orderedIds[index + 1]] : nil

            if let order = Self.manualOrder(between: previous, and: next) {
                try WishRecordStore.updateWish(id: wishId, now: now, in: db) { $0.manualOrder = order }
                return
            }
            // 간격이 좁거나 순서가 꼬였으면 화면 순서대로 다시 매긴다. 값이 바뀐 줄만 갱신한다
            for (position, id) in orderedIds.enumerated() where orders[id] != Double(position + 1) {
                try WishRecordStore.updateWish(id: id, now: now, in: db) { $0.manualOrder = Double(position + 1) }
            }
        }
    }

    func addWish(_ wish: Wish) -> Result<Wish, RepositoryError> {
        return write { db, now in
            var wish = wish
            // 새 위시는 정렬과 상관없이 그 카테고리의 맨 위 순서 값을 받는다 (GH-73 R-8)
            wish.manualOrder = try Self.topManualOrder(category: wish.category.rawValue, in: db)
            try WishRecordStore.insert(wish, now: now, in: db)
            return try Self.fetchExisting(id: wish.id, in: db)
        }
    }

    func updateWish(_ wish: Wish) -> Result<Wish, RepositoryError> {
        let checkedAt = now()
        return write { db, now in
            let newCategoryTop = try Self.topManualOrder(category: wish.category.rawValue, in: db)
            try WishRecordStore.updateWish(id: wish.id, now: now, in: db) { record in
                // 카테고리를 바꾸면 새 카테고리의 맨 위로 간다 (GH-73 R-8)
                if record.category != wish.category.rawValue {
                    record.manualOrder = newCategoryTop
                }
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
                // 수정 문서가 사진·편지 블록도 같이 저장한다 (GH-61 R-11)
                record.photoFileName = wish.photoFileName
                record.futureLetter = wish.futureLetter
                record.futureLetterSealedAt = wish.futureLetterSealedAt
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

    /// 카테고리에서 가장 위(가장 작은 값)보다 1 작은 값
    private static func topManualOrder(category: String, in db: Database) throws -> Double {
        let minimum = try WishRecordStore.aliveWishes()
            .filter(WishRecord.Columns.category == category)
            .select(min(WishRecord.Columns.manualOrder), as: Double?.self)
            .fetchOne(db) ?? nil
        return (minimum ?? 1) - 1
    }

    /// 앞뒤 값 사이의 새 값. 사이가 너무 좁거나 순서가 꼬였으면 nil (다시 매겨야 한다)
    private static func manualOrder(between previous: Double?, and next: Double?) -> Double? {
        switch (previous, next) {
        case let (previous?, next?):
            return next - previous > 1e-6 ? (previous + next) / 2 : nil
        case let (previous?, nil):
            return previous + 1
        case let (nil, next?):
            return next - 1
        case (nil, nil):
            return 0
        }
    }

    private static func savings(wishId: String, in db: Database) throws -> [WishSaving] {
        WishSaving.latestFirst(
            try WishRecordStore.aliveSavings(wishId: wishId, in: db)
                .map { WishSaving(id: $0.id, amount: $0.amount, createdAt: $0.createdAt) }
        )
    }

    private static func journals(wishId: String, in db: Database) throws -> [WishJournal] {
        WishJournal.latestFirst(
            try WishRecordStore.aliveJournals(wishId: wishId, in: db)
                .map { WishJournal(id: $0.id, text: $0.text, createdAt: $0.createdAt) }
        )
    }
}

/// 상세 "이어지는 싶" 섹션에 보일 체인 (GH-84 R-4, R-6~R-8)
struct WishChain: Equatable {
    /// 앞 위시 최대 개수. 지금 위시까지 10개를 넘으면 맨 앞을 접는다 (R-7)
    static let maxPreviousCount = 9

    /// 앞 → 뒤 순서. 지금 위시는 빠진다
    let previous: [Wish]
    let current: Wish
    /// 지금 위시 바로 다음으로 이어 적은 위시들(갈래 허용, 만든 순서)
    let next: [Wish]
    /// 접어 둔 앞선 싶 수
    let hiddenPreviousCount: Int

    /// 지금 위시가 체인에서 몇 번째인지
    var position: Int { hiddenPreviousCount + previous.count + 1 }
    /// 지금 위시 하나만 남으면 섹션을 숨긴다 (R-6)
    var isEmpty: Bool { previous.isEmpty && next.isEmpty }

    init(previous: [Wish], current: Wish, next: [Wish], hiddenPreviousCount: Int = 0) {
        self.previous = previous
        self.current = current
        self.next = next
        self.hiddenPreviousCount = hiddenPreviousCount
    }

    /// 지운 위시는 건너뛰고 앞뒤를 바로 잇는다(R-6). 한 번 본 id 를 다시 만나면 멈춘다(R-7 순환 참조)
    init?(records: [WishRecord], currentId: String) {
        let byId = Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        guard let currentRecord = byId[currentId], currentRecord.deletedAt == nil else { return nil }

        func alivePrevious(of id: String) -> String? {
            var candidate = byId[id]?.previousWishId
            var visited: Set<String> = [id]
            while let candidateId = candidate, let record = byId[candidateId], !visited.contains(candidateId) {
                guard record.deletedAt != nil else { return candidateId }
                visited.insert(candidateId)
                candidate = record.previousWishId
            }
            return nil
        }

        var chain: [WishRecord] = []
        var seen: Set<String> = [currentId]
        var cursor = alivePrevious(of: currentId)
        while let id = cursor, !seen.contains(id), let record = byId[id] {
            chain.insert(record, at: 0)
            seen.insert(id)
            cursor = alivePrevious(of: id)
        }
        let nextRecords = records
            .filter { $0.deletedAt == nil && !seen.contains($0.id) && alivePrevious(of: $0.id) == currentId }
            .sorted { $0.createdAt < $1.createdAt }

        func wish(_ record: WishRecord) -> Wish {
            Wish(record: record, steps: [], savings: [], notifications: [])
        }
        let shown = chain.suffix(Self.maxPreviousCount)
        self.init(
            previous: shown.map(wish),
            current: wish(currentRecord),
            next: nextRecords.map(wish),
            hiddenPreviousCount: chain.count - shown.count
        )
    }
}
