import RealmSwift

protocol WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish]
    
    func fetchNotFinishCount(category: Category) -> Int
    
    func finishWish(wish: Wish) -> Result<Wish, RepositoryError>
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
}
