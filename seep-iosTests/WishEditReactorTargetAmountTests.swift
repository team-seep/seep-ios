import XCTest

@testable import seep_ios_dev

/// 수정 화면 목표 금액 (GH-16 R-1·R-7). 수정해도 모은 돈 기록은 그대로인지 본다.
final class WishEditReactorTargetAmountTests: XCTestCase {
    private var mockWishService: MockWishService!
    private var reactor: WishEditReactor!
    private var poppedWishes: [Wish] = []

    override func tearDown() {
        mockWishService = nil
        reactor = nil
        poppedWishes = []
        super.tearDown()
    }

    private let savings = [
        WishSaving(id: "s-2", amount: 50_000),
        WishSaving(id: "s-1", amount: 30_000)
    ]

    private func makeReactor(category: seep_ios_dev.Category = .wantToGet, targetAmount: Int) {
        mockWishService = MockWishService()
        reactor = WishEditReactor(
            wish: Wish(
                id: "wish-1",
                emoji: "🎧",
                category: category,
                title: "에어팟 맥스",
                targetAmount: targetAmount,
                savings: savings
            ),
            wishService: mockWishService,
            notificationManager: MockNotificationManager()
        )
        _ = reactor.state // 상태 스트림을 연결해야 action 이 처리된다
        _ = reactor.popupWithWishPublisher.subscribe(onNext: { [weak self] wish in
            self?.poppedWishes.append(wish)
        })
        reactor.action.onNext(.tapDeadlineSwitch(false))
    }

    // MARK: GH-16 TC12

    func test_GH16_TC12_목표금액을지우고_수정완료하면_targetAmount0으로저장되고_기록은남는다() {
        // Given
        makeReactor(targetAmount: 769_000)
        XCTAssertEqual(reactor.currentState.targetAmount, 769_000)

        // When
        reactor.action.onNext(.inputTargetAmount(0))
        reactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(mockWishService.updatedWishes.first?.wish.targetAmount, 0)
        XCTAssertEqual(poppedWishes.first?.targetAmount, 0)
        XCTAssertEqual(poppedWishes.first?.savings.map(\.id), ["s-2", "s-1"])
    }

    func test_GH16_TC12_목표금액을바꾸고_수정완료하면_새목표금액과_기존기록이함께돌아간다() {
        // Given
        makeReactor(targetAmount: 769_000)

        // When
        reactor.action.onNext(.inputTargetAmount(500_000))
        reactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(mockWishService.updatedWishes.first?.wish.targetAmount, 500_000)
        XCTAssertEqual(poppedWishes.first?.savings.count, 2)
    }

    // MARK: GH-16 TC13

    func test_GH16_TC13_카테고리를하고싶어요로바꿔_수정완료하면_targetAmount0으로저장되고_기록은남는다() {
        // Given
        makeReactor(targetAmount: 769_000)

        // When
        reactor.action.onNext(.tapCategory(.wantToDo))
        reactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(mockWishService.updatedWishes.first?.wish.category, .wantToDo)
        XCTAssertEqual(mockWishService.updatedWishes.first?.wish.targetAmount, 0)
        XCTAssertEqual(poppedWishes.first?.savings.count, 2)
    }
}
