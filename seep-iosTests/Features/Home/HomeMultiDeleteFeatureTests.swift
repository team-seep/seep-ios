import XCTest

@testable import seep_ios

/// 홈 여러 개 골라 지우기 (GH-86 R-3~R-5)
final class HomeMultiDeleteFeatureTests: HomeFeatureTestCase {
    private let wishes = [
        Wish(id: "a", title: "서핑"),
        Wish(id: "b", title: "마라톤"),
        Wish(id: "c", title: "피아노"),
        Wish(id: "d", title: "목도리")
    ]

    private func selecting() -> HomeViewModel {
        let sut = makeSut()
        load(sut, wishes: wishes)
        sut.send(.tapSelect)
        return sut
    }

    // MARK: GH-86 TC4

    func test_GH86_TC4_3개를고르고삭제를확인하면_한번에지우고알림을취소한다() {
        // Given
        let sut = selecting()
        ["a", "b", "c"].forEach { id in sut.send(.tapWish(wishes.first { $0.id == id }!)) }

        // When
        sut.send(.tapDeleteSelected)
        let confirmCount = sut.state.deleteConfirmCount
        sut.send(.confirmDeleteSelected)

        // Then
        XCTAssertEqual(confirmCount, 3)
        XCTAssertEqual(repository.deleteWishesCalls.map(Set.init), [["a", "b", "c"]])
        XCTAssertEqual(Set(notificationManager.cancelledWishes.map(\.id)), ["a", "b", "c"])
        XCTAssertFalse(sut.state.isSelecting)
        XCTAssertEqual(sut.state.items.map(\.id), ["d"])
    }

    func test_GH86_TC4_전체선택은_한번더누르면모두해제한다() {
        // Given
        let sut = selecting()

        // When
        sut.send(.selectAll)
        let all = sut.state.selectedIds
        sut.send(.selectAll)

        // Then
        XCTAssertEqual(all, ["a", "b", "c", "d"])
        XCTAssertTrue(sut.state.selectedIds.isEmpty)
    }

    // MARK: GH-86 TC5

    func test_GH86_TC5_하나도고르지않으면_삭제확인이뜨지않는다() {
        // Given
        let sut = selecting()

        // When
        sut.send(.tapDeleteSelected)

        // Then
        XCTAssertNil(sut.state.deleteConfirmCount)
        XCTAssertTrue(repository.deleteWishesCalls.isEmpty)
    }

    // MARK: GH-86 TC6

    func test_GH86_TC6_저장에실패하면_아무것도지우지않고에러를보여준다() {
        // Given
        let sut = selecting()
        repository.deleteWishesResult = .failure(.writeFailed)
        sut.send(.tapWish(wishes[0]))
        sut.send(.tapDeleteSelected)

        // When
        sut.send(.confirmDeleteSelected)

        // Then
        XCTAssertNotNil(sut.state.errorMessage)
        XCTAssertTrue(notificationManager.cancelledWishes.isEmpty)
        XCTAssertTrue(sut.state.isSelecting)
        XCTAssertEqual(sut.state.items.count, 4)
    }

    // MARK: GH-86 TC7

    func test_GH86_TC7_선택모드에서카드를누르면_상세로가지않고선택이바뀐다() {
        // Given
        let sut = selecting()

        // When
        sut.send(.tapWish(wishes[1]))
        let afterFirst = sut.state.selectedIds
        sut.send(.tapWish(wishes[1]))

        // Then
        XCTAssertEqual(afterFirst, ["b"])
        XCTAssertTrue(sut.state.selectedIds.isEmpty)
        XCTAssertTrue(router.wishPath.isEmpty)
    }

    func test_GH86_R3_취소하면_선택모드를나간다() {
        // Given
        let sut = selecting()
        sut.send(.tapWish(wishes[0]))

        // When
        sut.send(.cancelSelection)

        // Then
        XCTAssertFalse(sut.state.isSelecting)
        XCTAssertTrue(sut.state.selectedIds.isEmpty)
        XCTAssertTrue(sut.state.isSelectButtonVisible)
    }

    // MARK: GH-86 TC8

    func test_GH86_TC8_선택모드진입과일괄삭제에_select_wishes와delete_selected_wishes로그가간다() {
        // Given
        let sut = selecting()
        sut.send(.tapWish(wishes[0]))
        sut.send(.tapWish(wishes[1]))
        sut.send(.tapDeleteSelected)

        // When
        sut.send(.confirmDeleteSelected)

        // Then
        XCTAssertEqual(clickEvents(objectId: .selectWishes).count, 1)
        let deletes = clickEvents(objectId: .deleteSelectedWishes)
        XCTAssertEqual(deletes.count, 1)
        XCTAssertEqual(deletes.first?.screen, .home)
        XCTAssertEqual(deletes.first?.extraParameters?[.count] as? Int, 2)
    }
}
