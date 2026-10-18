@testable import seep_ios_dev

final class MockWishRepository: WishRepository {
    var fetchWishesResult: [Wish] = []
    var fetchNotFinishCountResult: Int = 0
    var finishWishResult: Result<Wish, RepositoryError> = .success(Wish.mockData)
    var deleteWishCalledIds: [String] = []
    var toggleStepResult: Result<[WishStep], RepositoryError> = .success([])
    private(set) var finishWishCalls: [Wish] = []
    private(set) var toggleStepCalls: [(wishId: String, stepId: String)] = []
    var addSavingResult: Result<[WishSaving], RepositoryError> = .success([])
    var deleteSavingResult: Result<[WishSaving], RepositoryError> = .success([])
    private(set) var addSavingCalls: [(wishId: String, amount: Int)] = []
    private(set) var deleteSavingCalls: [(wishId: String, savingId: String)] = []
    /// nil 이면 호출된 위시 id·소감으로 만든 위시를 성공으로 돌려준다
    var updateFinishNoteResult: Result<Wish, RepositoryError>?
    private(set) var updateFinishNoteCalls: [(wishId: String, note: String)] = []
    var searchWishesResult: [Wish] = []
    private(set) var searchWishesCalls: [String] = []

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

    func toggleStep(wishId: String, stepId: String) -> Result<[WishStep], RepositoryError> {
        toggleStepCalls.append((wishId, stepId))
        return toggleStepResult
    }

    func addSaving(wishId: String, amount: Int) -> Result<[WishSaving], RepositoryError> {
        addSavingCalls.append((wishId, amount))
        return addSavingResult
    }

    func deleteSaving(wishId: String, savingId: String) -> Result<[WishSaving], RepositoryError> {
        deleteSavingCalls.append((wishId, savingId))
        return deleteSavingResult
    }

    func updateFinishNote(wishId: String, note: String) -> Result<Wish, RepositoryError> {
        updateFinishNoteCalls.append((wishId, note))
        return updateFinishNoteResult ?? .success(Wish(id: wishId, isSuccess: true, finishNote: note))
    }

    func searchWishes(keyword: String) -> [Wish] {
        searchWishesCalls.append(keyword)
        return searchWishesResult
    }
}
