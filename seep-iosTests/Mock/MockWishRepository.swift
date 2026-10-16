@testable import seep_ios_dev

final class MockWishRepository: WishRepository {
    var fetchWishesResult: [Wish] = []
    var fetchNotFinishCountResult: Int = 0
    var finishWishResult: Result<Wish, RepositoryError> = .success(Wish.mockData)
    var deleteWishCalledIds: [String] = []
    var addStepResult: Result<[WishStep], RepositoryError> = .success([])
    var toggleStepResult: Result<[WishStep], RepositoryError> = .success([])
    var deleteStepResult: Result<[WishStep], RepositoryError> = .success([])
    private(set) var finishWishCalls: [Wish] = []
    private(set) var addStepCalls: [(wishId: String, title: String)] = []
    private(set) var toggleStepCalls: [(wishId: String, stepId: String)] = []
    private(set) var deleteStepCalls: [(wishId: String, stepId: String)] = []

    func fetchWishes(category: Category, sort: HomeSortOrder, isOnlyFinished: Bool) -> [Wish] {
        return fetchWishesResult
    }

    func fetchNotFinishCount(category: Category) -> Int {
        return fetchNotFinishCountResult
    }

    func finishWish(wish: Wish) -> Result<Wish, RepositoryError> {
        finishWishCalls.append(wish)
        return finishWishResult
    }

    func deleteWish(id: String) {
        deleteWishCalledIds.append(id)
    }

    func addStep(wishId: String, title: String) -> Result<[WishStep], RepositoryError> {
        addStepCalls.append((wishId, title))
        return addStepResult
    }

    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError> {
        toggleStepCalls.append((wishId, stepId))
        return toggleStepResult
    }

    func deleteStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError> {
        deleteStepCalls.append((wishId, stepId))
        return deleteStepResult
    }
}
