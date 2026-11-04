import XCTest

@testable import seep_ios

/// 홈 "내가 정한 순서" — 정렬 시트·순서 바꾸기 모드 (GH-73)
final class HomeManualOrderFeatureTests: HomeFeatureTestCase {
    private let wishA = Wish(id: "a", title: "A", manualOrder: 1)
    private let wishB = Wish(id: "b", title: "B", manualOrder: 2)
    private let wishC = Wish(id: "c", title: "C", manualOrder: 3)

    private func makeManualSut(wishes: [Wish]) -> HomeViewModel {
        preference.homeSortOrder = .manualOrder
        let sut = makeSut()
        load(sut, wishes: wishes)
        return sut
    }

    // MARK: GH-73 TC1

    func test_GH73_TC1_내가정한순서를고르면_정렬이바뀌고순서바꾸기가보인다() {
        // Given
        let sut = makeSut()
        load(sut, wishes: [wishA, wishB])
        sut.send(.tapSortOrder)

        // When
        sut.send(.selectSortOrder(.manualOrder))

        // Then
        XCTAssertEqual(sut.state.sortOrder, .manualOrder)
        XCTAssertNil(sut.state.sheet)
        XCTAssertTrue(sut.state.isReorderButtonVisible)
    }

    func test_GH73_TC1_다른정렬에서는_순서바꾸기가보이지않는다() {
        // Given
        let sut = makeSut()

        // When
        load(sut, wishes: [wishA, wishB])

        // Then
        XCTAssertEqual(sut.state.sortOrder, .deadlineOrder)
        XCTAssertFalse(sut.state.isReorderButtonVisible)
    }

    // MARK: GH-73 TC2

    func test_GH73_TC2_고른정렬은_다시켜도유지된다() {
        // Given
        let sut = makeSut()
        sut.send(.selectSortOrder(.manualOrder))

        // When: 앱을 다시 켠다 (같은 저장소로 새 홈)
        let relaunched = makeSut()

        // Then
        XCTAssertEqual(preference.homeSortOrder, .manualOrder)
        XCTAssertEqual(relaunched.state.sortOrder, .manualOrder)
    }

    // MARK: GH-73 TC7

    func test_GH73_TC7_순서바꾸기중카테고리를바꾸면_모드가유지되고_그카테고리목록을읽는다() {
        // Given
        let sut = makeManualSut(wishes: [wishA, wishB])
        sut.send(.tapReorder)
        repository.fetchWishesResult = [
            Wish(id: "get-1", category: .wantToGet, title: "갖고 1", manualOrder: 1),
            Wish(id: "get-2", category: .wantToGet, title: "갖고 2", manualOrder: 2)
        ]

        // When
        sut.send(.selectCategory(.wantToGet))

        // Then
        XCTAssertTrue(sut.state.isReordering)
        XCTAssertEqual(sut.state.movableItems.map(\.id), ["get-1", "get-2"])
        XCTAssertTrue(repository.moveWishCalls.isEmpty)
    }

    // MARK: GH-73 TC8

    func test_GH73_TC8_순서바꾸기모드에서는_고정위시와옮길위시가나뉘고_완료하면모드가끝난다() {
        // Given
        let pinned = Wish(id: "p", title: "P", pinnedAt: Date(), manualOrder: 0)
        let finishing = Wish(id: "done", title: "방금 완료", isSuccess: true, manualOrder: 5)
        let sut = makeManualSut(wishes: [pinned, wishA, wishB])

        // When
        sut.send(.tapReorder)

        // Then
        XCTAssertTrue(sut.state.isReordering)
        XCTAssertEqual(sut.state.pinnedItems.map(\.id), ["p"])
        XCTAssertEqual(sut.state.movableItems.map(\.id), ["a", "b"])
        XCTAssertFalse(sut.state.isReorderButtonVisible)

        // When
        sut.send(.finishReorder)

        // Then
        XCTAssertFalse(sut.state.isReordering)
        XCTAssertFalse(HomeViewModel.State(sortOrder: .manualOrder, viewType: .list, items: [
            HomeWishItem(wish: finishing, photoStorage: photoStorage)
        ]).movableItems.contains { $0.id == "done" })
    }

    // MARK: GH-73 TC4, TC5 (화면 → 저장소 호출)

    func test_GH73_TC4_C를A와B사이로옮기면_옮긴순서로저장을요청한다() {
        // Given
        let sut = makeManualSut(wishes: [wishA, wishB, wishC])
        sut.send(.tapReorder)

        // When: 2번(C)을 1번 자리로
        sut.send(.moveWish(from: IndexSet(integer: 2), to: 1))

        // Then
        XCTAssertEqual(repository.moveWishCalls.map(\.wishId), ["c"])
        XCTAssertEqual(repository.moveWishCalls.first?.orderedIds, ["a", "c", "b"])
    }

    func test_GH73_TC5_맨위로옮겨도_고정위시는옮길목록에없다() {
        // Given
        let pinned = Wish(id: "p", title: "P", pinnedAt: Date(), manualOrder: 0)
        let sut = makeManualSut(wishes: [pinned, wishA, wishB])
        sut.send(.tapReorder)

        // When: B를 옮길 목록 맨 위(= 고정 위시 바로 아래)로
        sut.send(.moveWish(from: IndexSet(integer: 1), to: 0))

        // Then
        XCTAssertEqual(repository.moveWishCalls.first?.orderedIds, ["b", "a"])
    }

    // MARK: GH-73 TC9

    func test_GH73_TC9_정렬을고르면_sort_order클릭로그가type과함께한번전송된다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.selectSortOrder(.deadlineOrder))
        sut.send(.selectSortOrder(.latestOrder))
        sut.send(.selectSortOrder(.manualOrder))

        // Then
        let types = clickEvents(objectId: .sortOrder).compactMap { $0.extraParameters?[.type] as? String }
        XCTAssertEqual(types, ["deadline", "latest", "manual"])
        XCTAssertTrue(clickEvents(objectId: .sortOrder).allSatisfy { $0.screen == .home })
    }

    // MARK: GH-73 TC10

    func test_GH73_TC10_순서바꾸기와옮기기는_각각클릭로그를한번보낸다() {
        // Given
        let sut = makeManualSut(wishes: [wishA, wishB, wishC])

        // When
        sut.send(.tapReorder)
        sut.send(.moveWish(from: IndexSet(integer: 2), to: 0))

        // Then
        XCTAssertEqual(clickEvents(objectId: .reorderWishes).count, 1)
        let moves = clickEvents(objectId: .moveWish)
        XCTAssertEqual(moves.count, 1)
        XCTAssertEqual(moves.first?.extraParameters?[.objectType] as? LogObjectType, .card)
    }

    func test_GH73_TC10_제자리에놓으면_저장도로그도없다() {
        // Given
        let sut = makeManualSut(wishes: [wishA, wishB])
        sut.send(.tapReorder)

        // When
        sut.send(.moveWish(from: IndexSet(integer: 0), to: 0))

        // Then
        XCTAssertTrue(repository.moveWishCalls.isEmpty)
        XCTAssertTrue(clickEvents(objectId: .moveWish).isEmpty)
    }

    // MARK: GH-73 TC11

    func test_GH73_TC11_진행중위시가1개뿐이면_순서바꾸기가보이지않는다() {
        // Given / When
        let pinned = Wish(id: "p", title: "P", pinnedAt: Date(), manualOrder: 0)
        let sut = makeManualSut(wishes: [pinned, wishA])

        // Then
        XCTAssertFalse(sut.state.isReorderButtonVisible)

        // When: 눌러도 모드에 들어가지 않는다
        sut.send(.tapReorder)

        // Then
        XCTAssertFalse(sut.state.isReordering)
    }
}
