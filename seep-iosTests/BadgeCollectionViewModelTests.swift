import XCTest
import Combine

@testable import seep_ios_dev

final class BadgeCollectionViewModelTests: XCTestCase {
    // MARK: GH-35 TC15

    func test_GH35_TC15_화면에진입하면_화면명은badge_collection이고_헤드라인수와카드8개가계산값과같다() {
        // Given: 하고 싶어요 1개 + 갖고 싶어요 1개 완료 → 첫 싶·첫 하고·첫 갖고 = 3개
        let repository = MockWishRepository()
        repository.fetchAllFinishedWishesResult = [
            Wish(category: .wantToDo, finishDate: Date(), isSuccess: true),
            Wish(category: .wantToGet, finishDate: Date(), isSuccess: true)
        ]
        let viewModel = BadgeCollectionViewModel(dependency: .init(wishRepository: repository))

        // When
        viewModel.input.viewWillAppear.send(())

        // Then
        XCTAssertEqual(viewModel.output.screenName.rawValue, "badge_collection")
        XCTAssertEqual(viewModel.output.badges.value.count, 8)
        XCTAssertEqual(viewModel.output.earnedCount.value, 3)
        XCTAssertEqual(
            viewModel.output.badges.value.filter(\.isEarned).map(\.type),
            [.finish1, .firstWantToDo, .firstWantToGet]
        )
    }

    func test_GH35_TC15_다시나타나면_완료취소가반영되어다시계산한다() {
        // Given
        let repository = MockWishRepository()
        repository.fetchAllFinishedWishesResult = [Wish(category: .wantToDo, finishDate: Date(), isSuccess: true)]
        let viewModel = BadgeCollectionViewModel(dependency: .init(wishRepository: repository))
        viewModel.input.viewWillAppear.send(())
        XCTAssertEqual(viewModel.output.earnedCount.value, 2)

        // When
        repository.fetchAllFinishedWishesResult = []
        viewModel.input.viewWillAppear.send(())

        // Then
        XCTAssertEqual(viewModel.output.earnedCount.value, 0)
    }
}
