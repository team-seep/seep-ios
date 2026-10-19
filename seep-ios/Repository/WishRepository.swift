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
