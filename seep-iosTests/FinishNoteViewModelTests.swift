import XCTest
import Combine

@testable import seep_ios_dev

/// 완료 소감 바텀시트 (GH-25 R-1~R-3, R-7).
final class FinishNoteViewModelTests: XCTestCase {
    private var mockRepository: MockWishRepository!
    private var mockLogManager: MockLogManager!
    private var cancellables: Set<AnyCancellable>!

    private let wish = Wish(id: "finish-note-wish", emoji: "🏃", title: "하프 마라톤 완주하기", isSuccess: true)

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
        mockLogManager = MockLogManager()
        cancellables = []
    }

    override func tearDown() {
        mockRepository = nil
        mockLogManager = nil
        cancellables = nil
        super.tearDown()
    }

    private func makeViewModel() -> FinishNoteViewModel {
        return FinishNoteViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: mockRepository, logManager: mockLogManager)
        )
    }

    private func objectIds(of events: [any LogEventType]) -> [String] {
        return events.compactMap { $0.parameters[ParameterName.objectId.rawValue] as? String }
    }

    // MARK: GH-25 TC2

    func test_GH25_TC2_공백만입력하면_남기기가비활성이고_눌러도저장되지않는다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputNote.send("   ")
        viewModel.input.didTapSave.send(())

        // Then
        XCTAssertFalse(viewModel.output.isSaveEnabled.value)
        XCTAssertTrue(mockRepository.updateFinishNoteCalls.isEmpty)
    }

    func test_GH25_TC2_처음에는_남기기가비활성이다() {
        // Given
        let viewModel = makeViewModel()

        // When
        // (입력 없음)

        // Then
        XCTAssertFalse(viewModel.output.isSaveEnabled.value)
        XCTAssertEqual(viewModel.output.countText.value, "0/40")
    }

    // MARK: GH-25 TC3

    func test_GH25_TC3_41자를입력하면_40자까지만남는다() {
        // Given
        let viewModel = makeViewModel()
        let text = String(repeating: "가", count: 41)

        // When
        viewModel.input.inputNote.send(text)

        // Then
        XCTAssertEqual(viewModel.output.noteText.value, String(repeating: "가", count: 40))
        XCTAssertEqual(viewModel.output.countText.value, "40/40")
        XCTAssertTrue(viewModel.output.isSaveEnabled.value)
    }

    func test_GH25_TC3_이모지는_한글자로센다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.input.inputNote.send("최고👍🏻")

        // Then
        XCTAssertEqual(viewModel.output.countText.value, "3/40")
    }

    // MARK: GH-25 TC4

    func test_GH25_TC4_남기기를누르면_앞뒤공백을자른소감을저장하고_시트를닫는다() {
        // Given
        let viewModel = makeViewModel()
        var routes: [FinishNoteViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        viewModel.input.inputNote.send("  최고!  ")

        // When
        viewModel.input.didTapSave.send(())

        // Then
        XCTAssertEqual(mockRepository.updateFinishNoteCalls.map(\.wishId), [wish.id])
        XCTAssertEqual(mockRepository.updateFinishNoteCalls.map(\.note), ["최고!"])
        XCTAssertEqual(routes.count, 1)
        guard case .dismiss = routes.first else {
            return XCTFail("시트를 닫아야 한다")
        }
    }

    // MARK: GH-25 TC5

    func test_GH25_TC5_다음에할게요를누르면_저장하지않고_시트를닫는다() {
        // Given
        let viewModel = makeViewModel()
        var routes: [FinishNoteViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        viewModel.input.inputNote.send("저장하면 안 되는 소감")

        // When
        viewModel.input.didTapSkip.send(())

        // Then
        XCTAssertTrue(mockRepository.updateFinishNoteCalls.isEmpty)
        guard case .dismiss = routes.first else {
            return XCTFail("시트를 닫아야 한다")
        }
    }

    // MARK: GH-25 TC9

    func test_GH25_TC9_시트가뜨면_impression로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.input.viewDidLoad.send(())

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        let event = mockLogManager.sentEvents.first
        XCTAssertEqual(event?.name, .impression)
        XCTAssertEqual(event?.screen, .finishNoteBottomSheet)
        XCTAssertEqual(event?.parameters[ParameterName.screen.rawValue] as? String, "finish_note_bottom_sheet")
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "card")
        XCTAssertEqual(event?.parameters[ParameterName.objectId.rawValue] as? String, "finish_note_sheet")
    }

    func test_GH25_TC9_남기기로저장에성공하면_save_finish_note클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel()
        viewModel.input.inputNote.send("최고!")

        // When
        viewModel.input.didTapSave.send(())

        // Then
        let clicks = mockLogManager.sentEvents.filter { $0.name == .click }
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
        viewModel.input.didTapSkip.send(())

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        let event = mockLogManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.screen, .finishNoteBottomSheet)
        XCTAssertEqual(event?.parameters[ParameterName.objectType.rawValue] as? String, "button")
        XCTAssertEqual(objectIds(of: mockLogManager.sentEvents), ["skip_finish_note"])
    }

    // MARK: GH-25 TC12

    func test_GH25_TC12_저장에실패하면_시트를유지하고_에러알럿을띄우며_저장로그가없다() {
        // Given
        mockRepository.updateFinishNoteResult = .failure(.writeFailed)
        let viewModel = makeViewModel()
        var routes: [FinishNoteViewModel.Route] = []
        var savedWishes: [Wish] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)
        viewModel.output.didSaveNote
            .sink { savedWishes.append($0) }
            .store(in: &cancellables)
        viewModel.input.inputNote.send("최고!")

        // When
        viewModel.input.didTapSave.send(())

        // Then
        XCTAssertEqual(routes.count, 1)
        guard case .showErrorAlert = routes.first else {
            return XCTFail("에러 알럿을 띄워야 한다")
        }
        XCTAssertTrue(savedWishes.isEmpty)
        XCTAssertTrue(mockLogManager.sentEvents.isEmpty)
    }
}
