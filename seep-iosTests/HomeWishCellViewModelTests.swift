import XCTest

@testable import seep_ios_dev

final class HomeWishCellViewModelTests: XCTestCase {
    // MARK: GH-5 TC6

    func test_GH5_TC6_단계0개인위시는_진행도가nil이라_숨겨진다() {
        // Given
        let wish = Wish(id: "wish-1", title: "단계 없는 위시")

        // When
        let viewModel = HomeWishCellViewModel(config: .init(wish: wish, viewType: .list))

        // Then
        XCTAssertNil(viewModel.output.stepProgress)
    }

    func test_GH5_TC6_단계가있으면_완료수와전체수를표시한다() {
        // Given
        let steps = [
            WishStep(title: "날짜 정하기", isDone: true, order: 0),
            WishStep(title: "숙소 알아보기", isDone: true, order: 1),
            WishStep(title: "항공권 예약하기", order: 2),
            WishStep(title: "짐 싸기", order: 3)
        ]
        let wish = Wish(id: "wish-1", title: "제주도 한 달 살기", steps: steps)

        // When
        let viewModel = HomeWishCellViewModel(config: .init(wish: wish, viewType: .list))

        // Then
        XCTAssertEqual(viewModel.output.stepProgress?.doneCount, 2)
        XCTAssertEqual(viewModel.output.stepProgress?.totalCount, 4)
        XCTAssertEqual(
            Strings.Home.stepProgressFormat(2, 4),
            "2/4"
        )
    }
}
