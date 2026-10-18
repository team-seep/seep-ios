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
    
    /// 카테고리와 무관하게 `finishDate`가 [from, to) 안인 완료 위시를 돌려준다 (GH-34 R-3).
    func fetchFinishedWishes(from: Date, to: Date) -> [Wish]
}

final class WishRepositoryImpl: WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        let searchTask = realm.objects(WishDTO.self)
            .filter { (isOnlyFinished ? ($0.isSuccess == isOnlyFinished) : true) && ($0.category == category.rawValue) }
            .map { Wish(dto: $0) }
        
        return searchTask.sorted(by: sort.orderFunction())
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
        
        do {
            try realm.commitWrite()
            var finishedWish = wish
            finishedWish.isSuccess = true
            finishedWish.finishDate = finishDate
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
    
    func fetchFinishedWishes(from: Date, to: Date) -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        return realm.objects(WishDTO.self)
            .filter("isSuccess == true AND finishDate >= %@ AND finishDate < %@", from, to)
            .map { Wish(dto: $0) }
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
