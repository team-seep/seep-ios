import RealmSwift

protocol WishServiceProtocol {
  func addWish(wish: Wish)
  func deleteWish(id: String)
  func searchWish(id: String) -> Wish?
  func updateWish(id: String, newWish: Wish)
  func cancelFinishWish(id: String)
  func finishWish(id: String)
  func fetchAllWishes(category: Category) -> [Wish]
  func getFinishCount(category: Category) -> Int
  func fetchFinishedWishes(category: Category) -> [Wish]
  func getWishCount() -> Int
  func getWishCount(category: Category) -> Int
}


struct WishService: WishServiceProtocol {
  func addWish(wish: Wish) {
    let realm = try! Realm()
    
    try! realm.write {
      realm.add(WishDTO(wish: wish))
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
  
  func searchWish(id: String) -> Wish? {
    guard let realm = try? Realm() else { return nil }
    let searchTask = realm.objects(WishDTO.self).filter { $0._id == id }
    guard let targetObject = searchTask.first else { return nil }
    
    return Wish(dto: targetObject)
  }
  
  func updateWish(id: String, newWish: Wish) {
    guard let realm = try? Realm() else { return }
    var item = self.searchWish(id: id)
    
    try! realm.write {
      item?.emoji = newWish.emoji
      item?.category = newWish.category
      item?.title = newWish.title
      item?.endDate = newWish.endDate
      item?.memo = newWish.memo
      item?.hashtag = newWish.hashtag
    }
  }
  
    func cancelFinishWish(id: String) {
        guard let realm = try? Realm() else { return }
        
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == id }).first else {
            return
        }
        
        realm.beginWrite()
        targetObject.isSuccess = false
        targetObject.finishDate = nil
        try! realm.commitWrite()
    }
  
    func finishWish(id: String) {
        guard let realm = try? Realm() else { return }
        
        guard let targetObject = realm.objects(WishDTO.self).filter({ $0._id == id }).first else {
            return
        }
        
        realm.beginWrite()
        targetObject.isSuccess = true
        targetObject.finishDate = DateUtils.now()
        try! realm.commitWrite()
    }
  
    func fetchAllWishes(category: Category) -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        let searchTask = realm.objects(WishDTO.self)
            .filter { ($0.isSuccess == false) && ($0.category == category.rawValue) }
            .map { Wish(dto: $0) }
        
        return searchTask.sorted(by: Wish.deadlineOrder)
    }
  
    func getFinishCount(category: Category) -> Int {
        let realm = try! Realm()
        let searchTask = realm.objects(WishDTO.self)
            .filter { ($0.isSuccess == true) && ($0.category == category.rawValue) }
        
        return searchTask.count
    }
  
    func fetchFinishedWishes(category: Category) -> [Wish] {
        guard let realm = try? Realm() else { return [] }
        let searchTask = realm.objects(WishDTO.self)
            .filter { ($0.isSuccess == true) && ($0.category == category.rawValue) }
            .map { Wish(dto: $0) }
        
        return searchTask.sorted(by: Wish.finishOrder)
    }
  
    func getWishCount() -> Int {
        guard let realm = try? Realm() else { return 0 }
        let searchTask = realm.objects(WishDTO.self)
            .filter { $0.isSuccess == false }
        
        return searchTask.count
    }
  
    func getWishCount(category: Category) -> Int {
        guard let realm = try? Realm() else { return 0 }
        let searchTask = realm.objects(WishDTO.self)
            .filter { ($0.isSuccess == false) && ($0.category == category.rawValue) }
        
        return searchTask.count
    }
}
