import XCTest

@testable import seep_ios_dev

/// 작성·수정 Reactor 의 링크 저장 (GH-29 R-1, R-2). 링크 칸 ViewModel 이 넘긴 `WishLinkInput` 만으로 저장 여부가 정해진다.
final class WishLinkReactorTests: XCTestCase {
    private var mockWishService: MockWishService!
    private var writeReactor: WriteReactor!
    private var editReactor: WishEditReactor!

    private let link = "https://store.example.com/p/1"

    override func tearDown() {
        mockWishService = nil
        writeReactor = nil
        editReactor = nil
        super.tearDown()
    }

    private func makeWriteReactor(category: seep_ios_dev.Category = .wantToGet) {
        mockWishService = MockWishService()
        writeReactor = WriteReactor(
            category: category,
            wishService: mockWishService,
            userDefaults: UserDefaultsUtils(name: "test"),
            notificationManager: MockNotificationManager(),
            logManager: MockLogManager()
        )
        _ = writeReactor.state // 상태 스트림을 연결해야 action 이 처리된다
        writeReactor.action.onNext(.inputTitle("노이즈캔슬링 헤드폰"))
        writeReactor.action.onNext(.tapDeadlineSwitch(false))
    }

    private func makeEditReactor(category: seep_ios_dev.Category = .wantToGet, link: String) {
        mockWishService = MockWishService()
        editReactor = WishEditReactor(
            wish: Wish(id: "wish-1", emoji: "🎧", category: category, title: "노이즈캔슬링 헤드폰", link: link),
            wishService: mockWishService,
            notificationManager: MockNotificationManager()
        )
        _ = editReactor.state
        editReactor.action.onNext(.tapDeadlineSwitch(false))
    }

    // MARK: GH-29 TC2

    func test_GH29_TC2_갖고싶어요에서링크를넣고_작성완료하면_link가저장된다() {
        // Given
        makeWriteReactor()
        writeReactor.action.onNext(.inputLink(WishLinkInput(text: link)))

        // When
        writeReactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.count, 1)
        XCTAssertEqual(mockWishService.addedWishes.first?.link, link)
    }

    func test_GH29_TC2_링크칸이비어있으면_링크없이저장된다() {
        // Given
        makeWriteReactor()
        writeReactor.action.onNext(.inputLink(WishLinkInput(text: "")))

        // When
        writeReactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.first?.link, "")
    }

    // MARK: GH-29 TC3

    func test_GH29_TC3_링크형식이아니면_작성완료가비활성이고_눌러도저장되지않는다() {
        // Given
        makeWriteReactor()

        // When
        writeReactor.action.onNext(.inputLink(WishLinkInput(text: "헤드폰 매장 어딘가")))
        writeReactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(writeReactor.currentState.writeButtonState, .initial)
        XCTAssertTrue(mockWishService.addedWishes.isEmpty)
    }

    func test_GH29_TC3_링크형식이아니어도_하고싶어요로바꾸면_작성할수있고_링크는비운다() {
        // Given
        makeWriteReactor()
        writeReactor.action.onNext(.inputLink(WishLinkInput(text: "헤드폰 매장 어딘가")))

        // When
        writeReactor.action.onNext(.tapCategory(.wantToDo))
        writeReactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(writeReactor.currentState.writeButtonState, .active)
        XCTAssertEqual(mockWishService.addedWishes.first?.link, "")
    }

    func test_GH29_TC3_수정화면에서링크형식이아니면_수정완료가비활성이고_저장되지않는다() {
        // Given
        makeEditReactor(link: link)

        // When
        editReactor.action.onNext(.inputLink(WishLinkInput(text: "헤드폰 매장 어딘가")))
        editReactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(editReactor.currentState.editButtonState, .more)
        XCTAssertTrue(mockWishService.updatedWishes.isEmpty)
    }

    // MARK: GH-29 TC4

    func test_GH29_TC4_앞뒤공백포함링크를저장하면_공백이제거된값이저장된다() {
        // Given
        makeWriteReactor()
        writeReactor.action.onNext(.inputLink(WishLinkInput(text: "  \(link) \n")))

        // When
        writeReactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(mockWishService.addedWishes.first?.link, link)
    }

    // MARK: GH-29 TC6

    func test_GH29_TC6_미리보기를못불러와도_링크는저장된다() {
        // Given: 미리보기 실패는 링크 칸 ViewModel 안에서 끝나고, Reactor 에는 올바른 링크만 넘어온다
        makeWriteReactor()
        writeReactor.action.onNext(.inputLink(.valid(link)))

        // When
        writeReactor.action.onNext(.tapWriteButton)

        // Then
        XCTAssertEqual(writeReactor.currentState.writeButtonState, .active)
        XCTAssertEqual(mockWishService.addedWishes.first?.link, link)
    }

    // MARK: GH-29 TC7

    func test_GH29_TC7_링크있는갖고싶어요위시를_하고싶어요로바꿔저장하면_link는빈문자열이다() {
        // Given
        makeEditReactor(link: link)

        // When
        editReactor.action.onNext(.tapCategory(.wantToDo))
        editReactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(mockWishService.updatedWishes.first?.wish.category, .wantToDo)
        XCTAssertEqual(mockWishService.updatedWishes.first?.wish.link, "")
    }

    func test_GH29_TC7_링크를바꾸지않고수정완료하면_기존링크가그대로저장된다() {
        // Given
        makeEditReactor(link: link)

        // When
        editReactor.action.onNext(.tapEditButton)

        // Then
        XCTAssertEqual(mockWishService.updatedWishes.first?.wish.link, link)
    }

    // MARK: GH-29 TC9

    func test_GH29_TC9_링크필드가없는기존위시DTO는_link가빈문자열이다() {
        // Given
        let dto = WishDTO()
        dto.title = "예전 위시"

        // When
        let wish = Wish(dto: dto)

        // Then
        XCTAssertEqual(wish.link, "")
        XCTAssertEqual(WishDTO(wish: Wish(link: link)).link, link)
    }
}
