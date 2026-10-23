import XCTest

@testable import seep_ios_dev

/// 완료 소감 시트 (GH-25 R-1~R-3, R-7). 기존 FinishNoteViewModelTests 이전
final class FinishNoteFeatureTests: ViewModelTestCase {
    private var repository: MockWishRepository!
    private let wish = Wish(id: "finish-note-wish", emoji: "🏃", title: "하프 마라톤 완주하기", isSuccess: true)

    override func setUp() {
        super.setUp()
        repository = MockWishRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    private func makeViewModel() -> FinishNoteViewModel {
        FinishNoteViewModel(config: .init(wish: wish), dependency: .init(wishRepository: repository, logManager: logManager))
    }

    private func objectIds(of events: [any LogEventType]) -> [String] {
        events.compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
    }

    // MARK: GH-25 TC2

    func test_GH25_TC2_공백만입력하면_남기기가비활성이고_눌러도저장되지않는다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputNote("   "))
        viewModel.send(.tapSave)

        // Then
        XCTAssertFalse(viewModel.state.isSaveEnabled)
        XCTAssertTrue(repository.updateFinishNoteCalls.isEmpty)
    }

    func test_GH25_TC2_처음에는_남기기가비활성이다() {
        // Given / When
        let viewModel = makeViewModel()

        // Then
        XCTAssertFalse(viewModel.state.isSaveEnabled)
        XCTAssertEqual(viewModel.state.countText, "0/40")
    }

    // MARK: GH-25 TC3

    func test_GH25_TC3_41자를입력하면_40자까지만남는다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputNote(String(repeating: "가", count: 41)))

        // Then
        XCTAssertEqual(viewModel.state.noteText, String(repeating: "가", count: 40))
        XCTAssertEqual(viewModel.state.countText, "40/40")
        XCTAssertTrue(viewModel.state.isSaveEnabled)
    }

    func test_GH25_TC3_이모지는_한글자로센다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.inputNote("최고👍🏻"))

        // Then
        XCTAssertEqual(viewModel.state.countText, "3/40")
    }

    // MARK: GH-25 TC4

    func test_GH25_TC4_남기기를누르면_앞뒤공백을자른소감을저장하고_시트를닫는다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.inputNote("  최고!  "))

        // When
        viewModel.send(.tapSave)

        // Then
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.wishId), [wish.id])
        XCTAssertEqual(repository.updateFinishNoteCalls.map(\.note), ["최고!"])
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    // MARK: GH-25 TC5

    func test_GH25_TC5_다음에할게요를누르면_저장하지않고_시트를닫는다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.inputNote("저장하면 안 되는 소감"))

        // When
        viewModel.send(.tapSkip)

        // Then
        XCTAssertTrue(repository.updateFinishNoteCalls.isEmpty)
        XCTAssertEqual(viewModel.route, .dismiss)
    }

    // MARK: GH-25 TC9

    func test_GH25_TC9_시트가뜨면_impression로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .impression)
        XCTAssertEqual(event?.screen, .finishNoteBottomSheet)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "finish_note_bottom_sheet")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "card")
        XCTAssertEqual(event?.parameters[ParameterName.objectId.rawValue] as? String, "finish_note_sheet")
    }

    func test_GH25_TC9_남기기로저장에성공하면_save_finish_note클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.send(.inputNote("최고!"))

        // When
        viewModel.send(.tapSave)

        // Then
        let clicks = logManager.sentEvents.filter { $0.name == .click }
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .finishNoteBottomSheet)
        XCTAssertEqual(clicks.first?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(objectIds(of: clicks), ["save_finish_note"])
    }

    // MARK: GH-25 TC10

    func test_GH25_TC10_다음에할게요를누르면_skip_finish_note클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.send(.tapSkip)

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.screen, .finishNoteBottomSheet)
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(objectIds(of: logManager.sentEvents), ["skip_finish_note"])
    }

    // MARK: GH-25 TC12

    func test_GH25_TC12_저장에실패하면_시트를유지하고_에러알럿을띄우며_저장로그가없다() {
        // Given
        repository.updateFinishNoteResult = .failure(.writeFailed)
        let viewModel = makeViewModel()
        var savedWishes: [Wish] = []
        viewModel.onSave = { savedWishes.append($0) }
        viewModel.send(.inputNote("최고!"))

        // When
        viewModel.send(.tapSave)

        // Then
        guard case .errorAlert = viewModel.route else {
            return XCTFail("에러 알럿을 띄워야 한다")
        }
        XCTAssertTrue(savedWishes.isEmpty)
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }
}
