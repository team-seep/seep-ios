import XCTest

@testable import seep_ios_dev

/// 작성 화면에서 단계 설정 (GH-5 R-13~R-17). 작성 완료 때 위시와 단계가 함께 저장되는지 본다.
final class WriteReactorStepsTests: XCTestCase {
    private var mockWishService: MockWishService!
    private var reactor: WriteReactor!

    override func setUp() {
        super.setUp()
        mockWishService = MockWishService()
        reactor = WriteReactor(
            category: .wantToDo,
            wishService: mockWishService,
            userDefaults: UserDefaultsUtils(name: "test"),
            notificationManager: MockNotificationManager()
        )
        _ = reactor.state // 상태 스트림을 연결해야 action 이 처리된다
    }

    override func tearDown() {
        mockWishService = nil
        reactor = nil
        super.tearDown()
    }

    private func makeDraftSteps(_ titles: [String]) -> [WishStep] {
        return titles.enumerated().map { order, title in
            WishStep(title: title, order: order)
        }
    }

    private func inputRequiredFields() {
        reactor.action.onNext(.inputTitle("제주도 한 달 살기"))
        reactor.action.onNext(.tapDeadlineSwitch(false))
    }

    // MARK: GH-5 TC13

    func test_GH5_TC13_단계2개를추가하고_작성완료하면_위시와단계가함께저장된다() {
        // Given
        inputRequiredFields()
        reactor.action.onNext(.updateSteps(makeDraftSteps(["항공권 예약", "숙소 예약"])))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.count, 1)
        let steps = mockWishService.addedWishes.first?.steps ?? []
        XCTAssertEqual(steps.map(\.title), ["항공권 예약", "숙소 예약"])
        XCTAssertEqual(steps.map(\.order), [0, 1])
        XCTAssertEqual(steps.map(\.isDone), [false, false])
    }

    // MARK: GH-5 TC14

    func test_GH5_TC14_단계를추가했지만_작성완료전에닫으면_아무것도저장되지않는다() {
        // Given
        inputRequiredFields()
        reactor.action.onNext(.updateSteps(makeDraftSteps(["항공권 예약", "숙소 예약"])))

        // When
        reactor = nil // 닫기 = 화면과 Reactor 가 사라짐

        // Then
        XCTAssertTrue(mockWishService.addedWishes.isEmpty)
    }

    // MARK: GH-5 TC19

    func test_GH5_TC19_단계없이작성하면_단계0개로저장된다() {
        // Given
        inputRequiredFields()

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.count, 1)
        XCTAssertEqual(mockWishService.addedWishes.first?.steps, [])
    }
}
