import XCTest

@testable import seep_ios_dev

/// 배지 모아보기 (GH-35 R-5, GH-64 TC-801)
final class BadgeCollectionFeatureTests: ViewModelTestCase {
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
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(viewModel.screenName.rawValue, "badge_collection")
        XCTAssertEqual(viewModel.state.badges.count, 8)
        XCTAssertEqual(viewModel.state.earnedCount, 3)
        XCTAssertEqual(
            viewModel.state.badges.filter(\.isEarned).map(\.type),
            [.finish1, .firstWantToDo, .firstWantToGet]
        )
    }

    func test_GH35_TC15_다시나타나면_완료취소가반영되어다시계산한다() {
        // Given
        let repository = MockWishRepository()
        repository.fetchAllFinishedWishesResult = [Wish(category: .wantToDo, finishDate: Date(), isSuccess: true)]
        let viewModel = BadgeCollectionViewModel(dependency: .init(wishRepository: repository))
        viewModel.send(.onAppear)
        XCTAssertEqual(viewModel.state.earnedCount, 2)

        // When
        repository.fetchAllFinishedWishesResult = []
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(viewModel.state.earnedCount, 0)
    }

    // MARK: GH-64 TC801

    func test_GH64_TC801_받은배지3개면_8칸중3칸이얻은날을_나머지는진행도나조건을보인다() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let finishDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 3)) ?? Date()
        let repository = MockWishRepository()
        repository.fetchAllFinishedWishesResult = [
            Wish(category: .wantToDo, finishDate: finishDate, isSuccess: true),
            Wish(category: .wantToGo, finishDate: finishDate, isSuccess: true)
        ]
        let viewModel = BadgeCollectionViewModel(dependency: .init(wishRepository: repository, calendar: calendar))

        // When
        viewModel.send(.onAppear)

        // Then
        let badges = viewModel.state.badges
        XCTAssertEqual(badges.count, 8)
        XCTAssertEqual(badges.filter(\.isEarned).count, 3)
        XCTAssertTrue(badges.filter(\.isEarned).allSatisfy { $0.earnedDateText != nil })
        let locked = badges.filter { !$0.isEarned }
        XCTAssertTrue(locked.allSatisfy { $0.earnedDateText == nil && !$0.lockedDescription.isEmpty })
        XCTAssertEqual(locked.first { $0.type == .finish5 }?.lockedDescription, Strings.Badge.progressFormat(2, 5))
    }
}
