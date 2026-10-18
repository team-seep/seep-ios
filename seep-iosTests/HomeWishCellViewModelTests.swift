import XCTest
import Combine

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

    // MARK: GH-25 TC8

    func test_GH25_TC8_소감이있는완료위시는_소감을보여준다() {
        // Given
        let wish = Wish(id: "wish-1", title: "하프 마라톤 완주하기", isSuccess: true, finishNote: "끝까지 뛰었다!")

        // When
        let viewModel = HomeWishCellViewModel(config: .init(wish: wish, viewType: .list))

        // Then
        XCTAssertEqual(viewModel.output.finishNote, "끝까지 뛰었다!")
        XCTAssertEqual(Strings.Home.FinishNote.cellFormat("끝까지 뛰었다!"), "“끝까지 뛰었다!”")
    }

    func test_GH25_TC8_소감이없거나_미완료위시는_소감이nil이라_뱃지줄그대로다() {
        // Given
        let finishedWithoutNote = Wish(id: "wish-1", title: "완료·소감 없음", isSuccess: true)
        let notFinishedWithNote = Wish(id: "wish-2", title: "미완료", isSuccess: false, finishNote: "남아 있으면 안 되는 소감")

        // When
        let finishedViewModel = HomeWishCellViewModel(config: .init(wish: finishedWithoutNote, viewType: .list))
        let notFinishedViewModel = HomeWishCellViewModel(config: .init(wish: notFinishedWithNote, viewType: .list))

        // Then
        XCTAssertNil(finishedViewModel.output.finishNote)
        XCTAssertNil(notFinishedViewModel.output.finishNote)
    }

    // MARK: GH-33 TC1

    func test_GH33_TC1_고정된위시는_셀에핀이보인다() {
        // Given
        let pinned = Wish(id: "wish-1", title: "고정", pinnedAt: Date())
        let notPinned = Wish(id: "wish-2", title: "미고정")

        // When
        let pinnedViewModel = HomeWishCellViewModel(config: .init(wish: pinned, viewType: .list))
        let notPinnedViewModel = HomeWishCellViewModel(config: .init(wish: notPinned, viewType: .grid))

        // Then
        XCTAssertTrue(pinnedViewModel.output.isPinned)
        XCTAssertFalse(notPinnedViewModel.output.isPinned)
    }

    // MARK: GH-33 TC7

    func test_GH33_TC7_완료된위시는_고정메뉴를띄우지않고_메뉴입력도전달하지않는다() {
        // Given
        let finished = Wish(id: "wish-1", title: "완료", isSuccess: true)
        let viewModel = HomeWishCellViewModel(config: .init(wish: finished, viewType: .list))
        var forwarded: [Wish] = []
        let cancellable = viewModel.output.didTapPinMenu.sink { forwarded.append($0) }

        // When
        viewModel.input.didTapPinMenu.send(())

        // Then
        XCTAssertFalse(viewModel.output.canShowPinMenu)
        XCTAssertTrue(forwarded.isEmpty)
        cancellable.cancel()
    }

    func test_GH33_TC7_미완료위시는_고정메뉴를띄우고_메뉴입력을위시와함께전달한다() {
        // Given
        let wish = Wish(id: "wish-1", title: "미완료")
        let viewModel = HomeWishCellViewModel(config: .init(wish: wish, viewType: .list))
        var forwarded: [Wish] = []
        let cancellable = viewModel.output.didTapPinMenu.sink { forwarded.append($0) }

        // When
        viewModel.input.didTapPinMenu.send(())

        // Then
        XCTAssertTrue(viewModel.output.canShowPinMenu)
        XCTAssertEqual(forwarded.map(\.id), ["wish-1"])
        cancellable.cancel()
    }
}
