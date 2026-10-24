import XCTest

@testable import seep_ios_dev

/// 이어서 연 작성 화면 (GH-84 R-2)
final class WishFormChainFeatureTests: WishFormFeatureTestCase {
    private func makeChainedWrite(previousWishId: String = "olle-1") -> WishFormViewModel {
        let viewModel = WishFormViewModel(
            config: .init(mode: .add(.wantToGo), previousWishId: previousWishId),
            dependency: .init(
                wishRepository: wishRepository,
                notificationManager: notificationManager,
                logManager: logManager,
                userDefaults: userDefaults,
                linkMetadataProvider: linkMetadataProvider,
                linkPreviewCache: linkPreviewCache,
                photoStorage: photoStorage,
                linkPreviewDelay: nil,
                randomEmoji: { "🎲" },
                now: { [unowned self] in self.now }
            )
        )
        return viewModel
    }

    // MARK: GH-84 TC3

    func test_GH84_TC3_이어서연작성화면에서저장하면_새위시의앞위시id가들어간다() {
        // Given
        let sut = makeChainedWrite()
        sut.send(.inputTitle("올레길 21코스 완주하기"))

        // When
        sut.send(.tapSave)

        // Then
        XCTAssertEqual(sut.state.category, .wantToGo)
        XCTAssertEqual(wishRepository.addedWishes.first?.previousWishId, "olle-1")
        XCTAssertEqual(finishedWish(sut)?.previousWishId, "olle-1")
    }

    func test_GH84_TC3_그냥작성한위시는_앞위시가없다() {
        // Given
        let sut = makeWrite(category: .wantToDo)

        // When
        sut.send(.tapSave)

        // Then
        XCTAssertNil(wishRepository.addedWishes.first?.previousWishId)
        XCTAssertTrue(clickEvents(objectId: .saveChainedWish).isEmpty)
    }

    // MARK: GH-84 TC4

    func test_GH84_TC4_이어서연작성화면을저장없이닫으면_위시가생기지않는다() {
        // Given
        let sut = makeChainedWrite()

        // When
        sut.send(.tapClose)

        // Then
        XCTAssertEqual(sut.route, .finish(nil))
        XCTAssertTrue(wishRepository.addedWishes.isEmpty)
    }

    // MARK: GH-84 TC13

    func test_GH84_TC13_이어서연작성화면에서저장하면_save_chained_wish로그가한번전송된다() {
        // Given
        let sut = makeChainedWrite()
        sut.send(.inputTitle("올레길 21코스 완주하기"))

        // When
        sut.send(.tapSave)

        // Then
        let events = clickEvents(objectId: .saveChainedWish)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .write)
    }
}
