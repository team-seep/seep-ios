import XCTest

@testable import seep_ios_dev

/// 작성·수정 화면과 장소 (GH-31 R-1·R-10).
final class WishPlaceReactorTests: XCTestCase {
    private let place = WishPlace(name: "성산일출봉", address: "제주 서귀포시 성산읍 성산리 1", latitude: 33.458, longitude: 126.942)

    private func makeWriteReactor(category: seep_ios_dev.Category, wishService: MockWishService) -> WriteReactor {
        let reactor = WriteReactor(
            category: category,
            wishService: wishService,
            userDefaults: UserDefaultsUtils(name: "test"),
            notificationManager: MockNotificationManager(),
            logManager: MockLogManager()
        )
        _ = reactor.state // 상태 스트림을 연결해야 action 이 처리된다
        reactor.action.onNext(.inputTitle("성산일출봉에서 새해 일출 보기"))
        reactor.action.onNext(.tapDeadlineSwitch(false))
        return reactor
    }

    // MARK: GH-31 TC9

    func test_GH31_TC9_가고싶어요에서장소를고르고_작성완료하면_위시와함께장소가저장된다() {
        // Given
        let wishService = MockWishService()
        let reactor = makeWriteReactor(category: .wantToGo, wishService: wishService)
        reactor.action.onNext(.inputPlace(place))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(wishService.addedWishes.count, 1)
        XCTAssertEqual(wishService.addedWishes.first?.place, place)
    }

    func test_GH31_TC9_장소를고른뒤_다른카테고리로바꿔작성하면_장소는저장되지않는다() {
        // Given
        let wishService = MockWishService()
        let reactor = makeWriteReactor(category: .wantToGo, wishService: wishService)
        reactor.action.onNext(.inputPlace(place))
        reactor.action.onNext(.tapCategory(.wantToDo))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(wishService.addedWishes.first?.category, .wantToDo)
        XCTAssertNil(wishService.addedWishes.first?.place)
    }

    // MARK: GH-31 TC15

    func test_GH31_TC15_장소가붙은위시를_수정화면에서제목만바꿔저장하면_장소가유지된다() {
        // Given
        let wishService = MockWishService()
        let reactor = WishEditReactor(
            wish: Wish(id: "wish-1", emoji: "🌅", category: .wantToGo, title: "일출 보기", place: place),
            wishService: wishService,
            notificationManager: MockNotificationManager()
        )
        _ = reactor.state
        var poppedWishes: [Wish] = []
        _ = reactor.popupWithWishPublisher.subscribe(onNext: { poppedWishes.append($0) })
        reactor.action.onNext(.tapDeadlineSwitch(false))
        reactor.action.onNext(.inputTitle("성산일출봉에서 새해 일출 보기"))

        // When
        reactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(poppedWishes.first?.title, "성산일출봉에서 새해 일출 보기")
        XCTAssertEqual(poppedWishes.first?.place, place)
        XCTAssertEqual(wishService.updatedWishes.first?.wish.place, place)
    }
}
