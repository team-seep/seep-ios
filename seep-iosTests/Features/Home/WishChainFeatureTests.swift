import XCTest

@testable import seep_ios

/// 싶 잇기 — 완료 소감 시트의 "이어서 적기" (GH-84 R-1)
final class WishChainFeatureTests: HomeFeatureTestCase {
    private let olle = Wish(id: "olle-1", emoji: "🥾", category: .wantToGo, title: "제주 올레길 1코스 걷기")

    /// 홈에서 완료해 소감 시트를 띄운다
    private func finishFromHome() -> (HomeViewModel, FinishNoteViewModel?) {
        var finished = olle
        finished.isSuccess = true
        finished.finishDate = Date()
        repository.finishWishResult = .success(finished)
        repository.fetchWishResult = [finished]
        let sut = makeSut()
        load(sut, wishes: [olle])
        sut.send(.tapFinish(olle))
        return (sut, finishNoteViewModel(of: sut))
    }

    // MARK: GH-84 TC1

    func test_GH84_TC1_소감시트에서이어서적기를누르면_시트가닫히고같은카테고리작성화면이열린다() {
        // Given
        let (sut, sheet) = finishFromHome()

        // When
        sheet?.send(.tapChainNext)
        let sheetRoute = sheet?.route
        sut.send(.sheetDismissed)

        // Then
        XCTAssertEqual(sheetRoute, .dismiss)
        XCTAssertEqual(router.writeCategory, .wantToGo)
        XCTAssertEqual(router.writePreviousWishId, "olle-1")
    }

    func test_GH84_TC1_작성화면이닫히면_앞위시id도비운다() {
        // Given
        router.openChainedWrite(from: olle)

        // When
        router.writeCategory = nil

        // Then
        XCTAssertNil(router.writePreviousWishId)
    }

    // MARK: GH-84 TC2

    func test_GH84_TC2_소감을입력하고이어서적기를누르면_소감이저장된다() {
        // Given
        let (_, sheet) = finishFromHome()
        sheet?.send(.inputNote("  바다 보면서 걸으니 좋았어요 "))

        // When
        sheet?.send(.tapChainNext)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.note), ["바다 보면서 걸으니 좋았어요"])
        XCTAssertEqual(sheet?.route, .dismiss)
    }

    func test_GH84_TC2_소감저장이실패하면_이어서적지않는다() {
        // Given
        let (sut, sheet) = finishFromHome()
        repository.updateFinishNoteResult = .failure(.writeFailed)
        sheet?.send(.inputNote("좋았어요"))

        // When
        sheet?.send(.tapChainNext)
        sut.send(.sheetDismissed)

        // Then
        guard case .errorAlert = sheet?.route else { return XCTFail("에러 알럿이 없다") }
        XCTAssertNil(router.writeCategory)
    }

    // MARK: GH-84 TC12

    func test_GH84_TC12_소감시트에서이어서적기를누르면_chain_next_wish로그가한번전송된다() {
        // Given
        let (_, sheet) = finishFromHome()

        // When
        sheet?.send(.tapChainNext)

        // Then
        let events = clickEvents(objectId: .chainNextWish)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .finishNoteBottomSheet)
    }
}
