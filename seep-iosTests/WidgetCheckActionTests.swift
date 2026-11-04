import XCTest

@testable import seep_ios

/// 체크 위젯의 체크 판정·보조 문구 (GH-48 R-2, R-3, R-11)
final class WidgetCheckActionTests: XCTestCase {
    private func makeSteps(total: Int, doneCount: Int) -> [WishStep] {
        return (0..<total).map { index in
            WishStep(id: "step-\(index + 1)", title: "단계\(index + 1)", isDone: index < doneCount, order: index)
        }
    }

    // MARK: GH-48 TC1

    func test_GH48_TC1_단계5개중1개완료면_두번째단계체크로판정한다() {
        // Given
        let wish = Wish(title: "제주도 한 달 살기", steps: makeSteps(total: 5, doneCount: 1))

        // When
        let action = WidgetCheckAction.make(wish: wish)

        // Then
        XCTAssertEqual(action, .checkStep(id: "step-2"))
    }

    func test_GH48_TC1_단계순서가섞여저장돼있어도_order순첫미완료단계를체크한다() {
        // Given
        let steps = [
            WishStep(id: "c", title: "세번째", order: 2),
            WishStep(id: "a", title: "첫번째", isDone: true, order: 0),
            WishStep(id: "b", title: "두번째", order: 1)
        ]
        let wish = Wish(title: "위시", steps: steps)

        // When
        let action = WidgetCheckAction.make(wish: wish)

        // Then
        XCTAssertEqual(action, .checkStep(id: "b"))
    }

    // MARK: GH-48 TC2

    func test_GH48_TC2_단계3개중2개완료면_세번째단계까지완료하고위시완료로판정한다() {
        // Given
        let wish = Wish(title: "하프 마라톤", steps: makeSteps(total: 3, doneCount: 2))

        // When
        let action = WidgetCheckAction.make(wish: wish)

        // Then
        XCTAssertEqual(action, .finishWish(lastStepId: "step-3"))
    }

    // MARK: GH-48 TC3

    func test_GH48_TC3_단계없는위시면_위시완료로판정한다() {
        // Given
        let wish = Wish(title: "기타로 노래 한 곡 치기")

        // When
        let action = WidgetCheckAction.make(wish: wish)

        // Then
        XCTAssertEqual(action, .finishWish(lastStepId: nil))
    }

    func test_GH48_TC3_단계를모두끝냈지만완료전이면_위시완료로판정한다() {
        // Given
        let wish = Wish(title: "위시", steps: makeSteps(total: 2, doneCount: 2))

        // When
        let action = WidgetCheckAction.make(wish: wish)

        // Then
        XCTAssertEqual(action, .finishWish(lastStepId: nil))
    }

    // MARK: GH-48 TC4

    func test_GH48_TC4_단계5개중1개완료면_다음단계제목과2of5를보여준다() {
        // Given
        let wish = Wish(title: "제주도 한 달 살기", steps: makeSteps(total: 5, doneCount: 1))

        // When
        let caption = WidgetCheckAction.caption(wish: wish)

        // Then
        XCTAssertEqual(caption, "다음 단계 · 단계2 2/5")
    }

    // MARK: GH-48 TC5

    func test_GH48_TC5_단계없는위시면_누르면완료를보여준다() {
        // Given
        let wish = Wish(title: "기타로 노래 한 곡 치기")

        // When
        let caption = WidgetCheckAction.caption(wish: wish)

        // Then
        XCTAssertEqual(caption, "누르면 완료")
    }

    func test_GH48_TC5_완료한위시면_다시누르면취소문구를보여준다() {
        // Given
        let wish = Wish(title: "기타로 노래 한 곡 치기", isSuccess: true)

        // When
        let caption = WidgetCheckAction.caption(wish: wish)

        // Then
        XCTAssertEqual(caption, "이뤘어요! · 다시 누르면 취소")
    }
}
