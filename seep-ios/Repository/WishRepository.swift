import RealmSwift

protocol WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish]
    
    func fetchNotFinishCount(category: Category) -> Int
}

final class WishRepositoryImpl: WishRepository {
    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        let searchTask = realm.objects(WishDTO.self)
            .filter { ($0.isSuccess == isOnlyFinished) && ($0.category == category.rawValue) }
            .map { Wish(dto: $0) }
        
        
        return searchTask.sorted(by: sort.orderFunction())
    }
    
    func fetchNotFinishCount(category: Category) -> Int {
        guard let realm = try? Realm() else { return 0 }
        let searchTask = realm.objects(WishDTO.self)
            .filter { ($0.isSuccess == false) && ($0.category == category.rawValue) }
        
        return searchTask.count
    }
}
