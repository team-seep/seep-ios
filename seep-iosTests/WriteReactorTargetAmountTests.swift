import XCTest

@testable import seep_ios_dev

/// 작성 화면 목표 금액 (GH-16 R-1·R-2) + 작성 완료 로그.
final class WriteReactorTargetAmountTests: XCTestCase {
    private var mockWishService: MockWishService!
    private var mockLogManager: MockLogManager!
    private var reactor: WriteReactor!

    override func tearDown() {
        mockWishService = nil
        mockLogManager = nil
        reactor = nil
        super.tearDown()
    }

    private func makeReactor(category: seep_ios_dev.Category) {
        mockWishService = MockWishService()
        mockLogManager = MockLogManager()
        reactor = WriteReactor(
            category: category,
            wishService: mockWishService,
            userDefaults: UserDefaultsUtils(name: "test"),
            notificationManager: MockNotificationManager(),
            logManager: mockLogManager
        )
        _ = reactor.state // 상태 스트림을 연결해야 action 이 처리된다
        reactor.action.onNext(.inputTitle("에어팟 맥스"))
        reactor.action.onNext(.tapDeadlineSwitch(false))
    }

    private var writeClickEvents: [ClickEvent] {
        return mockLogManager.sentEvents
            .compactMap { $0 as? ClickEvent }
            .filter { ($0.extraParameters?[.objectId] as? LogObjectId) == .write }
    }

    // MARK: GH-16 TC1

    func test_GH16_TC1_갖고싶어요에서_목표금액769000을입력하고_작성완료하면_targetAmount가저장된다() {
        // Given
        makeReactor(category: .wantToGet)
        reactor.action.onNext(.inputTargetAmount(769_000))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.count, 1)
        XCTAssertEqual(mockWishService.addedWishes.first?.targetAmount, 769_000)
        XCTAssertEqual(mockWishService.addedWishes.first?.savings, [])
    }

    // MARK: GH-16 TC2

    func test_GH16_TC2_갖고싶어요에서입력후_다른카테고리로바꿔저장하면_targetAmount는0이다() {
        // Given
        makeReactor(category: .wantToGet)
        reactor.action.onNext(.inputTargetAmount(769_000))
        reactor.action.onNext(.tapCategory(.wantToDo))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.first?.category, .wantToDo)
        XCTAssertEqual(mockWishService.addedWishes.first?.targetAmount, 0)
    }

    func test_GH16_TC2_다른카테고리로갔다가_갖고싶어요로돌아오면_입력했던목표금액이저장된다() {
        // Given
        makeReactor(category: .wantToGet)
        reactor.action.onNext(.inputTargetAmount(769_000))
        reactor.action.onNext(.tapCategory(.wantToGo))
        reactor.action.onNext(.tapCategory(.wantToGet))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.first?.targetAmount, 769_000)
    }

    // MARK: GH-16 TC10

    func test_GH16_TC10_목표금액이있으면_작성완료로그에_has_target_amount_true가붙는다() {
        // Given
        makeReactor(category: .wantToGet)
        reactor.action.onNext(.inputTargetAmount(769_000))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(writeClickEvents.count, 1)
        XCTAssertEqual(writeClickEvents.first?.screen, .write)
        XCTAssertEqual(writeClickEvents.first?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(writeClickEvents.first?.extraParameters?[.hasTargetAmount] as? Bool, true)
    }

    func test_GH16_TC10_목표금액이없으면_작성완료로그에_has_target_amount_false가붙는다() {
        // Given
        makeReactor(category: .wantToGet)

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(writeClickEvents.count, 1)
        XCTAssertEqual(writeClickEvents.first?.extraParameters?[.hasTargetAmount] as? Bool, false)
    }

    func test_GH16_TC10_필수값이없어작성이안되면_작성완료로그를보내지않는다() {
        // Given
        makeReactor(category: .wantToGet)
        reactor.action.onNext(.inputTitle(""))

        // When
        reactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertTrue(mockWishService.addedWishes.isEmpty)
        XCTAssertTrue(writeClickEvents.isEmpty)
    }
}
