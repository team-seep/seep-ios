import XCTest
import Combine

@testable import seep_ios_dev

final class WishStepsViewModelTests: XCTestCase {
    private var mockRepository: MockWishRepository!
    private var mockLogManager: MockLogManager!
    private var cancellables: Set<AnyCancellable>!

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

    private func makeViewModel(steps: [WishStep]) -> WishStepsViewModel {
        let wish = Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: steps)
        return WishStepsViewModel(
            config: .init(mode: .persisted(wish)),
            dependency: .init(wishRepository: mockRepository, logManager: mockLogManager)
        )
    }

    private func makeSteps(count: Int, doneCount: Int = 0) -> [WishStep] {
        return (0..<count).map { index in
            WishStep(id: "step-\(index)", title: "단계 \(index)", isDone: index < doneCount, order: index)
        }
    }

    private func collectToasts(_ viewModel: WishStepsViewModel) -> () -> [String] {
        var toasts: [String] = []
        viewModel.output.toast
            .sink { toasts.append($0) }
            .store(in: &cancellables)
        return { toasts }
    }

    private func makeEditViewModel(steps: [WishStep]) -> WishStepsViewModel {
        return WishStepsViewModel(
            config: .init(mode: .draft(steps: steps, screenName: .wishEdit)),
            dependency: .init(wishRepository: mockRepository, logManager: mockLogManager)
        )
    }

    // MARK: GH-5 TC1

    func test_GH5_TC1_수정화면에서_단계0개인위시에_단계를추가하면_미완료단계1개가된다() {
        // Given
        let viewModel = makeEditViewModel(steps: [])
        var updated: [[WishStep]] = []
        viewModel.output.didUpdateSteps
            .sink { updated.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.addStep.send("  날짜 정하기 ")

        // Then
        XCTAssertEqual(viewModel.output.steps.value.map(\.title), ["날짜 정하기"])
        XCTAssertEqual(viewModel.output.steps.value.map(\.isDone), [false])
        XCTAssertEqual(viewModel.output.steps.value.map(\.order), [0])
        XCTAssertEqual(updated.count, 1)
        XCTAssertTrue(mockRepository.toggleStepCalls.isEmpty)
    }

    // MARK: GH-5 TC2

    func test_GH5_TC2_3개중1개완료에서_미완료단계를체크하면_진행도가2of3이된다() {
        // Given
        let steps = makeSteps(count: 3, doneCount: 1)
        let viewModel = makeViewModel(steps: steps)
        var toggled = steps
        toggled[1].isDone = true
        mockRepository.toggleStepResult = .success(toggled)

        // When
        viewModel.input.didTapStep.send(1)

        // Then
        XCTAssertEqual(mockRepository.toggleStepCalls.map(\.stepId), ["step-1"])
        XCTAssertEqual(viewModel.output.progress.value?.doneCount, 2)
        XCTAssertEqual(viewModel.output.progress.value?.totalCount, 3)
    }

    // MARK: GH-5 TC3

    func test_GH5_TC3_수정화면에서_단계10개면_추가하지않고_추가버튼이비활성이다() {
        // Given
        let viewModel = makeEditViewModel(steps: makeSteps(count: 10))
        let toasts = collectToasts(viewModel)
        var routes: [WishStepsViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapAdd.send(())
        viewModel.input.addStep.send("열한 번째 단계")

        // Then
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(viewModel.output.steps.value.count, 10)
        XCTAssertFalse(viewModel.output.isAddEnabled.value)
        XCTAssertEqual(toasts(), [Strings.Detail.Step.Toast.maxCount, Strings.Detail.Step.Toast.maxCount])
    }

    func test_GH5_TC3_수정화면에서_단계9개면_추가버튼이활성이고_입력창을띄운다() {
        // Given
        let viewModel = makeEditViewModel(steps: makeSteps(count: 9))
        var routes: [WishStepsViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapAdd.send(())

        // Then
        XCTAssertTrue(viewModel.output.isAddEnabled.value)
        guard case .presentAddStepInput = routes.first else {
            return XCTFail("입력창 Route 가 와야 한다")
        }
    }

    // MARK: GH-5 TC4

    func test_GH5_TC4_수정화면에서_공백만입력하면_추가되지않는다() {
        // Given
        let viewModel = makeEditViewModel(steps: [])

        // When
        viewModel.input.addStep.send("   \n ")

        // Then
        XCTAssertTrue(viewModel.output.steps.value.isEmpty)
        XCTAssertTrue(mockLogManager.sentEvents.isEmpty)
    }

    func test_GH5_TC4_수정화면에서_30자를넘기면_추가되지않고_토스트가뜬다() {
        // Given
        let viewModel = makeEditViewModel(steps: [])
        let toasts = collectToasts(viewModel)

        // When
        viewModel.input.addStep.send(String(repeating: "가", count: 31))

        // Then
        XCTAssertTrue(viewModel.output.steps.value.isEmpty)
        XCTAssertEqual(toasts(), [Strings.Detail.Step.Toast.maxLength])
    }

    func test_GH5_TC4_수정화면에서_정확히30자는_추가된다() {
        // Given
        let viewModel = makeEditViewModel(steps: [])
        let title = String(repeating: "가", count: 30)

        // When
        viewModel.input.addStep.send(title)

        // Then
        XCTAssertEqual(viewModel.output.steps.value.map(\.title), [title])
    }

    // MARK: GH-5 TC5

    func test_GH5_TC5_수정화면에서_미완료단계를삭제하면_완료된단계만_isDone그대로남는다() {
        // Given
        let steps = makeSteps(count: 2, doneCount: 1) // step-0 완료, step-1 미완료
        let viewModel = makeEditViewModel(steps: steps)

        // When
        viewModel.input.deleteStep.send(1)

        // Then
        XCTAssertEqual(viewModel.output.steps.value.map(\.id), ["step-0"])
        XCTAssertEqual(viewModel.output.steps.value.map(\.isDone), [true])
        XCTAssertEqual(viewModel.output.steps.value.map(\.order), [0])
        XCTAssertEqual(WishStepProgress(steps: viewModel.output.steps.value), WishStepProgress(steps: [steps[0]]))
    }

    // MARK: GH-5 TC7

    func test_GH5_TC7_모든단계를체크해도_위시완료처리를호출하지않는다() {
        // Given
        let steps = makeSteps(count: 2, doneCount: 1)
        let viewModel = makeViewModel(steps: steps)
        let allDone = steps.map { step -> WishStep in
            var step = step
            step.isDone = true
            return step
        }
        mockRepository.toggleStepResult = .success(allDone)

        // When
        viewModel.input.didTapStep.send(1)

        // Then
        XCTAssertEqual(viewModel.output.progress.value?.doneCount, 2)
        XCTAssertTrue(mockRepository.finishWishCalls.isEmpty)
    }

    // MARK: GH-5 TC9

    func test_GH5_TC9_수정화면에서_단계를추가하면_wish_edit화면_add_step로그가1건전송된다() {
        // Given
        let viewModel = makeEditViewModel(steps: [])

        // When
        viewModel.input.addStep.send("날짜 정하기")

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        let event = mockLogManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters["screen"] as? String, "wish_edit")
        XCTAssertEqual(event?.parameters["object_type"] as? String, "button")
        XCTAssertEqual(event?.parameters["object_id"] as? String, "add_step")
    }

    // MARK: GH-5 TC22

    func test_GH5_TC22_상세에서는_단계를추가삭제할수없고_추가버튼이비활성이다() {
        // Given
        let steps = makeSteps(count: 2)
        let viewModel = makeViewModel(steps: steps)
        var routes: [WishStepsViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapAdd.send(())
        viewModel.input.addStep.send("새 단계")
        viewModel.input.deleteStep.send(0)

        // Then
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(viewModel.output.steps.value, steps)
        XCTAssertFalse(viewModel.output.isAddEnabled.value)
        XCTAssertTrue(mockLogManager.sentEvents.isEmpty)
    }

    func test_GH5_TC22_상세는_수정화면에서돌아온단계로_목록과진행도를갈아끼운다() {
        // Given
        let viewModel = makeViewModel(steps: makeSteps(count: 2))
        let editedSteps = makeSteps(count: 3, doneCount: 1)

        // When
        viewModel.input.reloadSteps.send(editedSteps)

        // Then
        XCTAssertEqual(viewModel.output.steps.value, editedSteps)
        XCTAssertEqual(viewModel.output.progress.value?.doneCount, 1)
        XCTAssertEqual(viewModel.output.progress.value?.totalCount, 3)
    }

    // MARK: GH-5 TC10

    func test_GH5_TC10_단계를체크하면_check_step클릭로그가_is_done과함께1건전송된다() {
        // Given
        let steps = makeSteps(count: 1)
        let viewModel = makeViewModel(steps: steps)
        var checked = steps
        checked[0].isDone = true
        mockRepository.toggleStepResult = .success(checked)

        // When
        viewModel.input.didTapStep.send(0)

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        let event = mockLogManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters["screen"] as? String, "wish_detail")
        XCTAssertEqual(event?.parameters["object_id"] as? String, "check_step")
        XCTAssertEqual(event?.parameters["is_done"] as? Bool, true)
    }

    func test_GH5_TC10_단계를해제하면_is_done이false로전송된다() {
        // Given
        let steps = makeSteps(count: 1, doneCount: 1)
        let viewModel = makeViewModel(steps: steps)
        var unchecked = steps
        unchecked[0].isDone = false
        mockRepository.toggleStepResult = .success(unchecked)

        // When
        viewModel.input.didTapStep.send(0)

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        XCTAssertEqual(mockLogManager.sentEvents.first?.parameters["is_done"] as? Bool, false)
    }

    // MARK: 작성 화면(draft) — GH-5 R-13~R-17

    private func makeDraftViewModel() -> WishStepsViewModel {
        return WishStepsViewModel(
            config: .init(mode: .draft(steps: [], screenName: .write)),
            dependency: .init(wishRepository: mockRepository, logManager: mockLogManager)
        )
    }

    // MARK: GH-5 TC15

    func test_GH5_TC15_작성화면에서_단계를추가삭제하면_저장소를부르지않고_Output만바뀐다() {
        // Given
        let viewModel = makeDraftViewModel()
        var updated: [[WishStep]] = []
        viewModel.output.didUpdateSteps
            .sink { updated.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.addStep.send("항공권 예약")
        viewModel.input.addStep.send("숙소 예약")
        viewModel.input.deleteStep.send(0)
        viewModel.input.didTapStep.send(0)

        // Then
        XCTAssertTrue(mockRepository.toggleStepCalls.isEmpty)
        XCTAssertEqual(viewModel.output.steps.value.map(\.title), ["숙소 예약"])
        XCTAssertEqual(viewModel.output.steps.value.map(\.isDone), [false])
        XCTAssertEqual(updated.count, 3)
        XCTAssertNil(viewModel.output.progress.value)
    }

    // MARK: GH-5 TC16

    func test_GH5_TC16_작성화면에서_3개중가운데를삭제하면_남은단계의순서가0과1로다시매겨진다() {
        // Given
        let viewModel = makeDraftViewModel()
        ["날짜 정하기", "항공권 예약", "숙소 예약"].forEach { viewModel.input.addStep.send($0) }

        // When
        viewModel.input.deleteStep.send(1)

        // Then
        XCTAssertEqual(viewModel.output.steps.value.map(\.title), ["날짜 정하기", "숙소 예약"])
        XCTAssertEqual(viewModel.output.steps.value.map(\.order), [0, 1])
    }

    // MARK: GH-5 TC17

    func test_GH5_TC17_작성화면에서_10개를넘거나_공백이나30자초과면_추가되지않는다() {
        // Given
        let viewModel = makeDraftViewModel()
        let toasts = collectToasts(viewModel)

        // When
        viewModel.input.addStep.send("   ")
        viewModel.input.addStep.send(String(repeating: "가", count: 31))
        (0..<11).forEach { viewModel.input.addStep.send("단계 \($0)") }

        // Then
        XCTAssertEqual(viewModel.output.steps.value.count, 10)
        XCTAssertFalse(viewModel.output.isAddEnabled.value)
        XCTAssertEqual(toasts(), [Strings.Detail.Step.Toast.maxLength, Strings.Detail.Step.Toast.maxCount])
    }

    // MARK: GH-5 TC20

    func test_GH5_TC20_작성화면에서_단계를추가하면_write화면_add_step로그가1건전송된다() {
        // Given
        let viewModel = makeDraftViewModel()

        // When
        viewModel.input.addStep.send("항공권 예약")

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        let event = mockLogManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters["screen"] as? String, "write")
        XCTAssertEqual(event?.parameters["object_type"] as? String, "button")
        XCTAssertEqual(event?.parameters["object_id"] as? String, "add_step")
    }
}
