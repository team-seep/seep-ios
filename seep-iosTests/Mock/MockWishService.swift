@testable import seep_ios_dev

/// WishServiceProtocol 스파이. 저장 호출만 기록하고 나머지는 빈 값을 돌려준다.
final class MockWishService: WishServiceProtocol {
    private(set) var addedWishes: [Wish] = []

    func addWish(wish: Wish) {
        addedWishes.append(wish)
    }

    func deleteWish(id: String) { }

    func searchWish(id: String) -> WishDTO? {
        return nil
    }

    func updateWish(id: String, newWish: Wish) { }

    func cancelFinishWish(id: String) { }

    func finishWish(id: String) { }

    func fetchAllWishes(category: Category) -> [Wish] {
        return []
    }

    func getFinishCount(category: Category) -> Int {
        return 0
    }

    func fetchFinishedWishes(category: Category) -> [Wish] {
        return []
    }

    func getWishCount() -> Int {
        return 0
    }

    func getWishCount(category: Category) -> Int {
        return 0
    }
}
