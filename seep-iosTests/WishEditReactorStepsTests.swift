import XCTest

@testable import seep_ios_dev

/// 수정 화면에서 단계 추가·삭제 (GH-5 R-18~R-20). 수정 완료 때 단계가 위시와 함께 저장되는지 본다.
final class WishEditReactorStepsTests: XCTestCase {
    private var mockWishService: MockWishService!
    private var reactor: WishEditReactor!

    override func tearDown() {
        mockWishService = nil
        reactor = nil
        super.tearDown()
    }

    private func makeReactor(steps: [WishStep]) {
        mockWishService = MockWishService()
        reactor = WishEditReactor(
            wish: Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: steps),
            wishService: mockWishService,
            notificationManager: MockNotificationManager()
        )
        _ = reactor.state // 상태 스트림을 연결해야 action 이 처리된다
        reactor.action.onNext(.tapDeadlineSwitch(false))
    }

    private func makeSteps(count: Int, doneCount: Int = 0) -> [WishStep] {
        return (0..<count).map { index in
            WishStep(id: "step-\(index)", title: "단계 \(index)", isDone: index < doneCount, order: index)
        }
    }

    // MARK: GH-5 TC1

    func test_GH5_TC1_수정화면에서_단계를추가하고_수정완료하면_단계가함께저장된다() {
        // Given
        makeReactor(steps: [])
        reactor.action.onNext(.updateSteps([WishStep(title: "날짜 정하기", order: 0)]))

        // When
        reactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(mockWishService.updatedWishes.map(\.id), ["wish-1"])
        let steps = mockWishService.updatedWishes.first?.wish.steps ?? []
        XCTAssertEqual(steps.map(\.title), ["날짜 정하기"])
        XCTAssertEqual(steps.map(\.isDone), [false])
    }

    // MARK: GH-5 TC5

    func test_GH5_TC5_미완료단계를지우고_수정완료하면_완료된단계만_isDone그대로저장된다() {
        // Given
        let steps = makeSteps(count: 2, doneCount: 1)
        makeReactor(steps: steps)
        reactor.action.onNext(.updateSteps([steps[0]]))

        // When
        reactor.action.onNext(.tapEditButton)

        // Then
        let saved = mockWishService.updatedWishes.first?.wish.steps ?? []
        XCTAssertEqual(saved.map(\.id), ["step-0"])
        XCTAssertEqual(saved.map(\.isDone), [true])
    }

    // MARK: GH-5 TC12

    func test_GH5_TC12_제목만바꿔저장하면_단계와완료상태가그대로저장된다() {
        // Given
        let steps = makeSteps(count: 3, doneCount: 2)
        makeReactor(steps: steps)
        reactor.action.onNext(.inputTitle("제주도 두 달 살기"))

        // When
        reactor.action.onNext(.tapEditButton)

        // Then
        let saved = mockWishService.updatedWishes.first?.wish
        XCTAssertEqual(saved?.title, "제주도 두 달 살기")
        XCTAssertEqual(saved?.steps, steps)
    }

    // MARK: GH-5 TC23

    func test_GH5_TC23_단계를바꿨지만_수정완료전에나가면_저장되지않는다() {
        // Given
        makeReactor(steps: makeSteps(count: 2))
        reactor.action.onNext(.updateSteps([]))

        // When
        reactor = nil // 뒤로 가기 = 화면과 Reactor 가 사라짐

        // Then
        XCTAssertTrue(mockWishService.updatedWishes.isEmpty)
    }
}
