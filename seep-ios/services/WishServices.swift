import RealmSwift

protocol WishServiceProtocol {
    func addWish(wish: Wish)
    
    func deleteWish(id: String)
    
    func searchWish(id: String) -> WishDTO?
    
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
    
    func searchWish(id: String) -> WishDTO? {
        guard let realm = try? Realm() else { return nil }
        let searchTask = realm.objects(WishDTO.self).filter { $0._id == id }
        guard let targetObject = searchTask.first else { return nil }
        
        return targetObject
    }
    
    func updateWish(id: String, newWish: Wish) {
        guard let realm = try? Realm() else { return }
        let item = self.searchWish(id: id)
        
        try! realm.write {
            item?.emoji = newWish.emoji
            item?.category = newWish.category.rawValue
            item?.title = newWish.title
            item?.date = newWish.endDate
            item?.notifications.removeAll()
            item?.notifications.append(objectsIn: newWish.notifications.map(NotificationDTO.init(seepNotification:)))
            item?.memo = newWish.memo
            item?.hashtag = newWish.hashtag
            // 수정 화면에서 바꾼 단계로 교체한다. 남은 단계는 id·isDone 을 그대로 가진다 (GH-5 R-19)
            item?.steps.removeAll()
            item?.steps.append(objectsIn: newWish.steps.map(WishStepDTO.init(step:)))
            // 목표 금액만 바꾸고 모은 돈 기록(savings)은 건드리지 않는다 (GH-16 R-7)
            item?.targetAmount = newWish.targetAmount
            // 링크는 문자열만 저장한다 (GH-29 R-7)
            item?.link = newWish.link
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
        // 다시 완료하면 소감을 새로 묻는다 (GH-25 R-6)
        targetObject.finishNote = ""
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
