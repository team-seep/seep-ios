import Foundation

import RealmSwift

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
}

final class WishRepositoryImpl: WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        let searchTask = realm.objects(WishDTO.self)
            .filter { (isOnlyFinished ? ($0.isSuccess == isOnlyFinished) : true) && ($0.category == category.rawValue) }
            .map { Wish(dto: $0) }
        
        return sort.sorted(Array(searchTask))
    }
    
    func fetchNotFinishCount(category: Category) -> Int {
        guard let realm = try? Realm() else { return 0 }
        let searchTask = realm.objects(WishDTO.self)
            .filter { ($0.isSuccess == false) && ($0.category == category.rawValue) }
        
        return searchTask.count
    }
    
    func finishWish(wish: Wish) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wish.id }).first else {
            return .failure(.targetNotFound)
        }
        
        let finishDate = DateUtils.now()
        realm.beginWrite()
        targetObject.isSuccess = true
        targetObject.finishDate = finishDate
        // 완료하면 고정을 푼다. 완료를 취소해도 돌아오지 않는다 (GH-33 R-6)
        targetObject.pinnedAt = nil
        
        do {
            try realm.commitWrite()
            var finishedWish = wish
            finishedWish.isSuccess = true
            finishedWish.finishDate = finishDate
            finishedWish.pinnedAt = nil
            return .success(finishedWish)
        } catch {
            return .failure(.writeFailed)
        }
    }
    
    func deleteWish(id: String) {
        guard let realm = try? Realm() else { return }
        let searchTask = realm.objects(WishDTO.self).filter { $0._id == id }
        guard let targetObject = searchTask.first else { return }
        
        try! realm.write{
            realm.delete(targetObject)
        }
    }
    
    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError> {
        return updateSteps(wishId: wishId) { steps in
            guard let step = steps.first(where: { $0._id == stepId }) else { return }
            step.isDone.toggle()
        }
    }
    
    func addSaving(wishId: String, amount: Int) -> Result<[WishSaving], RepositoryError> {
        return updateSavings(wishId: wishId) { savings in
            savings.append(SavingDTO(saving: WishSaving(amount: amount, createdAt: DateUtils.now())))
        }
    }
    
    func deleteSaving(wishId: String, savingId: String) -> Result<[WishSaving], RepositoryError> {
        return updateSavings(wishId: wishId) { savings in
            guard let index = savings.firstIndex(where: { $0._id == savingId }) else { return }
            savings.remove(at: index)
        }
    }
    
    func updateFinishNote(wishId: String, note: String) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                targetObject.finishNote = note
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        return .success(Wish(dto: targetObject))
    }
    
    func searchWishes(keyword: String) -> [Wish] {
        guard let keyword = WishSearchMatcher.normalize(keyword),
              let realm = try? Realm() else { return [] }
        
        // 해시태그 표시 이름(예: trip → 여행)까지 봐야 해서 Realm 쿼리 대신 도메인 모델에서 거른다
        return realm.objects(WishDTO.self)
            .map { Wish(dto: $0) }
            .filter { WishSearchMatcher.matches(wish: $0, keyword: keyword) }
    }
    
    func fetchFinishedWishes(from: Date, to: Date) -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        return realm.objects(WishDTO.self)
            .filter("isSuccess == true AND finishDate >= %@ AND finishDate < %@", from, to)
            .map { Wish(dto: $0) }
    }
    
    func fetchAllFinishedWishes() -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        let finished = realm.objects(WishDTO.self).filter("isSuccess == true")
        return Array(finished).map { Wish(dto: $0) }
    }
    
    func updatePin(wishId: String, isPinned: Bool) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                // 고정끼리 순서를 가르므로 시각까지 남긴다 (DateUtils.now()는 자정으로 잘라 쓰지 않는다)
                targetObject.pinnedAt = isPinned ? Date() : nil
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        return .success(Wish(dto: targetObject))
    }
    
    func markChecked(wishId: String) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                targetObject.lastCheckedAt = Date()
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        return .success(Wish(dto: targetObject))
    }
    
    func updatePlace(wishId: String, place: WishPlace?) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                targetObject.placeName = place?.name ?? ""
                targetObject.placeAddress = place?.address ?? ""
                targetObject.latitude = place?.latitude ?? 0
                targetObject.longitude = place?.longitude ?? 0
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        return .success(Wish(dto: targetObject))
    }
    
    func updatePhoto(wishId: String, fileName: String) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                targetObject.photoFileName = fileName
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        return .success(Wish(dto: targetObject))
    }
    
    func fetchWish(id: String) -> Wish? {
        guard let realm = try? Realm(),
              let targetObject = realm.objects(WishDTO.self).filter("_id == %@", id).first else { return nil }
        
        return Wish(dto: targetObject)
    }
    
    func cancelFinish(wishId: String) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                targetObject.isSuccess = false
                targetObject.finishDate = nil
                // 다시 완료하면 소감을 새로 묻는다 (GH-25 R-6)
                targetObject.finishNote = ""
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        return .success(Wish(dto: targetObject))
    }
    
    private func updateSavings(
        wishId: String,
        update: (List<SavingDTO>) -> Void
    ) -> Result<[WishSaving], RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                update(targetObject.savings)
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        return .success(WishSaving.latestFirst(Array(targetObject.savings).map(WishSaving.init(dto:))))
    }
    
    func addWish(_ wish: Wish) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        let dto = WishDTO(wish: wish)
        do {
            try realm.write {
                realm.add(dto)
            }
        } catch {
            return .failure(.writeFailed)
        }
        return .success(Wish(dto: dto))
    }

    func updateWish(_ wish: Wish) -> Result<Wish, RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter("_id == %@", wish.id).first else {
            return .failure(.targetNotFound)
        }

        do {
            try realm.write {
                targetObject.emoji = wish.emoji
                targetObject.category = wish.category.rawValue
                targetObject.title = wish.title
                targetObject.date = wish.endDate
                targetObject.notifications.removeAll()
                targetObject.notifications.append(objectsIn: wish.notifications.map(NotificationDTO.init(seepNotification:)))
                targetObject.memo = wish.memo
                targetObject.hashtag = wish.hashtag
                // 수정 폼에서 바꾼 단계로 교체한다. 남은 단계는 id·isDone 을 그대로 가진다 (GH-5 R-19)
                targetObject.steps.removeAll()
                targetObject.steps.append(objectsIn: wish.steps.map(WishStepDTO.init(step:)))
                // 목표 금액만 바꾸고 모은 돈 기록(savings)은 건드리지 않는다 (GH-16 R-7)
                targetObject.targetAmount = wish.targetAmount
                // 수정 폼이 고정 여부를 정해 넘긴다. 카테고리를 바꾸면 nil 이다 (GH-33 R-9)
                targetObject.pinnedAt = wish.pinnedAt
                // 링크는 문자열만 저장한다 (GH-29 R-7)
                targetObject.link = wish.link
                // 수정해 저장하면 손댄 것으로 보고 잠든 위시 판정 기준을 갱신한다 (GH-30 R-2)
                targetObject.lastCheckedAt = wish.lastCheckedAt ?? Date()
            }
        } catch {
            return .failure(.writeFailed)
        }
        return .success(Wish(dto: targetObject))
    }

    private func updateSteps(
        wishId: String,
        update: (List<WishStepDTO>) -> Void
    ) -> Result<[WishStep], RepositoryError> {
        guard let realm = try? Realm() else { return .failure(.noDatabase) }
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == wishId }).first else {
            return .failure(.targetNotFound)
        }
        
        do {
            try realm.write {
                update(targetObject.steps)
            }
        } catch {
            return .failure(.writeFailed)
        }
        
        let steps = Array(targetObject.steps)
            .map(WishStep.init(dto:))
            .sorted { $0.order < $1.order }
        return .success(steps)
    }
}
