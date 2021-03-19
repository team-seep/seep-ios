import RealmSwift

protocol WishServiceProtocol {
  
  func addWish(wish: Wish)
  func deleteWish(id: ObjectId)
  func searchWish(id: ObjectId) -> Wish?
  func fetchAllWishes(category: Category) -> [Wish]
}


struct WishService: WishServiceProtocol {
  
  func addWish(wish: Wish) {
    let realm = try! Realm()
    
    try! realm.write {
      realm.add(wish)
    }
  }
  
  func deleteWish(id: ObjectId) {
    guard let realm = try? Realm() else { return }
    let searchTask = realm.objects(Wish.self).filter { $0._id == id }
    guard let targetObject = searchTask.first else { return }
    
    try! realm.write{
      realm.delete(targetObject)
    }
  }
  
  func searchWish(id: ObjectId) -> Wish? {
    guard let realm = try? Realm() else { return nil }
    let searchTask = realm.objects(Wish.self).filter { $0._id == id }
    guard let targetObject = searchTask.first else { return nil }
    
    return targetObject
  }
  
  func fetchAllWishes(category: Category) -> [Wish] {
    guard let realm = try? Realm() else { return [] }
    let searchTask = realm.objects(Wish.self).filter { $0.category == category.rawValue }
    
    return searchTask.map { $0 }
  }
}
