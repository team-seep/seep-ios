import XCTest

@testable import seep_ios

/// 홈 선택 모드 "n개 보내기" → 골라서 보내기 미리보기 (GH-125 R-1, R-2, R-4, R-7, R-9)
final class HomeShareWishListFeatureTests: HomeFeatureTestCase {
    private let wishes = [
        Wish(id: "a", emoji: "🎧", category: .wantToGet, title: "에어팟 프로 3"),
        Wish(id: "b", emoji: "👟", category: .wantToGet, title: "러닝화 새로 하나"),
        Wish(id: "c", emoji: "📷", category: .wantToGet, title: "필름 카메라"),
        Wish(id: "d", emoji: "🪴", category: .wantToGet, title: "몬스테라 큰 화분")
    ]

    private func selecting() -> HomeViewModel {
        let sut = makeSut()
        sut.send(.selectCategory(.wantToGet))
        load(sut, wishes: wishes)
        sut.send(.tapSelect)
        return sut
    }

    private func tap(_ sut: HomeViewModel, _ ids: [String]) {
        ids.forEach { id in sut.send(.tapWish(wishes.first { $0.id == id }!)) }
    }

    // MARK: GH-125 TC1

    func test_GH125_TC1_하나도고르지않으면_보내기삭제가비활성이고미리보기가뜨지않는다() {
        // Given
        let sut = selecting()

        // When
        sut.send(.tapShareSelected)

        // Then
        XCTAssertFalse(sut.state.canActOnSelection)
        XCTAssertNil(sut.state.shareWishList)
        XCTAssertTrue(clickEvents(objectId: .shareSelectedWishes).isEmpty)
    }

    func test_GH125_TC1_하나라도고르면_보내기삭제가켜진다() {
        // Given
        let sut = selecting()

        // When
        tap(sut, ["b"])

        // Then
        XCTAssertTrue(sut.state.canActOnSelection)
    }

    // MARK: GH-125 TC2

    func test_GH125_TC2_3개를고르고보내기를누르면_홈순서대로미리보기에담긴다() {
        // Given
        let sut = selecting()
        tap(sut, ["c", "a", "d"])

        // When
        sut.send(.tapShareSelected)

        // Then
        let presentation = sut.state.shareWishList
        XCTAssertEqual(presentation?.category, .wantToGet)
        XCTAssertEqual(presentation?.wishes.map(\.id), ["a", "c", "d"])
        XCTAssertTrue(sut.state.isSelecting)
    }

    // MARK: GH-125 TC8

    func test_GH125_TC8_미리보기를닫으면_선택모드로돌아가고선택은유지된다() {
        // Given
        let sut = selecting()
        tap(sut, ["a", "b"])
        sut.send(.tapShareSelected)

        // When
        sut.send(.shareWishListDismissed)

        // Then
        XCTAssertNil(sut.state.shareWishList)
        XCTAssertTrue(sut.state.isSelecting)
        XCTAssertEqual(sut.state.selectedIds, ["a", "b"])
    }

    // MARK: GH-125 TC9

    func test_GH125_TC9_보내기를거친뒤에도_삭제흐름은그대로다() {
        // Given
        let sut = selecting()
        tap(sut, ["a", "b"])
        sut.send(.tapShareSelected)
        sut.send(.shareWishListDismissed)

        // When
        sut.send(.tapDeleteSelected)
        let confirmCount = sut.state.deleteConfirmCount
        sut.send(.confirmDeleteSelected)

        // Then
        XCTAssertEqual(confirmCount, 2)
        XCTAssertEqual(repository.deleteWishesCalls.map(Set.init), [["a", "b"]])
        XCTAssertFalse(sut.state.isSelecting)
    }

    // MARK: GH-125 TC10

    func test_GH125_TC10_n개보내기를누르면_share_selected_wishes로그가count와category로1번간다() {
        // Given
        let sut = selecting()
        tap(sut, ["a", "b", "c"])

        // When
        sut.send(.tapShareSelected)

        // Then
        let events = clickEvents(objectId: .shareSelectedWishes)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .home)
        XCTAssertEqual(events.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(events.first?.extraParameters?[.count] as? Int, 3)
        XCTAssertEqual(events.first?.extraParameters?[.category] as? String, seep_ios.Category.wantToGet.rawValue)
    }
}
