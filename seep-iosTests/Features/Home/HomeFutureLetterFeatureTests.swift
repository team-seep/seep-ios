import XCTest

@testable import seep_ios

/// 홈에서 완료할 때 "미래의 나에게" 편지가 열리는지 (GH-61 R-5)
final class HomeFutureLetterFeatureTests: HomeFeatureTestCase {
    // MARK: GH-61 TC7

    func test_GH61_TC7_홈목록의위시가봉인전값이어도_완료하면저장소의편지가열린다() {
        // Given: 홈 목록은 편지를 쓰기 전 값, 저장소에는 상세에서 봉인한 편지가 있다
        let listed = Wish(id: "piano", emoji: "🎹", title: "피아노로 한 곡 완주하기")
        var stored = listed
        stored.isSuccess = true
        stored.finishDate = Date()
        stored.futureLetter = "끝까지 쳐!"
        stored.futureLetterSealedAt = Date()
        repository.finishWishResult = .success(Wish(id: "piano", title: "피아노로 한 곡 완주하기", isSuccess: true))
        repository.fetchWishResult = [stored]
        let sut = makeSut()
        load(sut, wishes: [listed])

        // When
        sut.send(.tapFinish(listed))

        // Then
        XCTAssertEqual(finishNoteViewModel(of: sut)?.state.openedLetter?.body, "끝까지 쳐!")
    }
}
