@testable import seep_ios_dev

final class MockWishRepository: WishRepository {
    var fetchWishesResult: [Wish] = []
    var fetchNotFinishCountResult: Int = 0
    var finishWishResult: Result<Wish, RepositoryError> = .success(Wish.mockData)
    var deleteWishCalledIds: [String] = []

    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish] {
        return fetchWishesResult
    }

    func fetchNotFinishCount(category: Category) -> Int {
        return fetchNotFinishCountResult
    }

    func finishWish(wish: Wish) -> Result<Wish, RepositoryError> {
        return finishWishResult
    }

    func deleteWish(id: String) {
        deleteWishCalledIds.append(id)
    }
}
