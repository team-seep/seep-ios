import RealmSwift

protocol WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish]
    
    func fetchNotFinishCount(category: Category) -> Int
    
    func finishWish(wish: Wish) -> Result<Wish, RepositoryError>
    
    func deleteWish(id: String)
    
    /// 단계를 맨 뒤(order 최대 + 1)에 추가하고, 갱신된 단계 목록(order 오름차순)을 돌려준다.
    func addStep(wishId: String, title: String) -> Result<[WishStep], RepositoryError>
    
    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError>
    
    func deleteStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError>
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
    
    func addStep(wishId: String, title: String) -> Result<[WishStep], RepositoryError> {
        return updateSteps(wishId: wishId) { steps in
            let nextOrder = (steps.map(\.order).max() ?? -1) + 1
            steps.append(WishStepDTO(step: WishStep(title: title, order: nextOrder)))
        }
    }
    
    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError> {
        return updateSteps(wishId: wishId) { steps in
            guard let step = steps.first(where: { $0._id == stepId }) else { return }
            step.isDone.toggle()
        }
    }
    
    func deleteStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError> {
        return updateSteps(wishId: wishId) { steps in
            guard let index = steps.firstIndex(where: { $0._id == stepId }) else { return }
            steps.remove(at: index)
        }
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
