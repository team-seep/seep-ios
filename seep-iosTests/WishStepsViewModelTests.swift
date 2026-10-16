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
            config: .init(wish: wish),
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

    // MARK: GH-5 TC1

    func test_GH5_TC1_단계0개인위시에_단계를추가하면_미완료단계1개가저장된다() {
        // Given
        let viewModel = makeViewModel(steps: [])
        let savedStep = WishStep(id: "new", title: "날짜 정하기", isDone: false, order: 0)
        mockRepository.addStepResult = .success([savedStep])

        // When
        viewModel.input.addStep.send("  날짜 정하기 ")

        // Then
        XCTAssertEqual(mockRepository.addStepCalls.map(\.wishId), ["wish-1"])
        XCTAssertEqual(mockRepository.addStepCalls.map(\.title), ["날짜 정하기"])
        XCTAssertEqual(viewModel.output.steps.value, [savedStep])
        XCTAssertEqual(viewModel.output.steps.value.first?.isDone, false)
        XCTAssertEqual(viewModel.output.progress.value, WishStepProgress(steps: [savedStep]))
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

    func test_GH5_TC3_단계10개에서_추가를시도하면_저장하지않고_추가버튼이비활성이다() {
        // Given
        let viewModel = makeViewModel(steps: makeSteps(count: 10))
        let toasts = collectToasts(viewModel)
        var routes: [WishStepsViewModel.Route] = []
        viewModel.output.route
            .sink { routes.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapAdd.send(())
        viewModel.input.addStep.send("열한 번째 단계")

        // Then
        XCTAssertTrue(mockRepository.addStepCalls.isEmpty)
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(viewModel.output.steps.value.count, 10)
        XCTAssertFalse(viewModel.output.isAddEnabled.value)
        XCTAssertEqual(toasts(), [Strings.Detail.Step.Toast.maxCount, Strings.Detail.Step.Toast.maxCount])
    }

    func test_GH5_TC3_단계9개면_추가버튼이활성이고_입력창을띄운다() {
        // Given
        let viewModel = makeViewModel(steps: makeSteps(count: 9))
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

    func test_GH5_TC4_공백만입력하면_저장되지않는다() {
        // Given
        let viewModel = makeViewModel(steps: [])

        // When
        viewModel.input.addStep.send("   \n ")

        // Then
        XCTAssertTrue(mockRepository.addStepCalls.isEmpty)
        XCTAssertTrue(viewModel.output.steps.value.isEmpty)
        XCTAssertTrue(mockLogManager.sentEvents.isEmpty)
    }

    func test_GH5_TC4_30자를넘기면_저장되지않고_토스트가뜬다() {
        // Given
        let viewModel = makeViewModel(steps: [])
        let toasts = collectToasts(viewModel)

        // When
        viewModel.input.addStep.send(String(repeating: "가", count: 31))

        // Then
        XCTAssertTrue(mockRepository.addStepCalls.isEmpty)
        XCTAssertEqual(toasts(), [Strings.Detail.Step.Toast.maxLength])
    }

    func test_GH5_TC4_정확히30자는_저장된다() {
        // Given
        let viewModel = makeViewModel(steps: [])
        let title = String(repeating: "가", count: 30)

        // When
        viewModel.input.addStep.send(title)

        // Then
        XCTAssertEqual(mockRepository.addStepCalls.map(\.title), [title])
    }

    // MARK: GH-5 TC5

    func test_GH5_TC5_단계2개중하나를삭제하면_남은1개만유지되고_진행도가갱신된다() {
        // Given
        let steps = makeSteps(count: 2, doneCount: 1)
        let viewModel = makeViewModel(steps: steps)
        mockRepository.deleteStepResult = .success([steps[1]])
        var updatedSteps: [[WishStep]] = []
        viewModel.output.didUpdateSteps
            .sink { updatedSteps.append($0) }
            .store(in: &cancellables)

        // When
        viewModel.input.deleteStep.send(0)

        // Then
        XCTAssertEqual(mockRepository.deleteStepCalls.map(\.stepId), ["step-0"])
        XCTAssertEqual(viewModel.output.steps.value, [steps[1]])
        XCTAssertEqual(viewModel.output.progress.value?.doneCount, 0)
        XCTAssertEqual(viewModel.output.progress.value?.totalCount, 1)
        XCTAssertEqual(updatedSteps, [[steps[1]]])
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

    func test_GH5_TC9_단계를추가하면_add_step클릭로그가1건전송된다() {
        // Given
        let viewModel = makeViewModel(steps: [])
        mockRepository.addStepResult = .success([WishStep(title: "날짜 정하기", order: 0)])

        // When
        viewModel.input.addStep.send("날짜 정하기")

        // Then
        XCTAssertEqual(mockLogManager.sentEvents.count, 1)
        let event = mockLogManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.parameters["screen"] as? String, "wish_detail")
        XCTAssertEqual(event?.parameters["object_type"] as? String, "button")
        XCTAssertEqual(event?.parameters["object_id"] as? String, "add_step")
    }

    func test_GH5_TC9_저장에실패하면_로그를보내지않는다() {
        // Given
        let viewModel = makeViewModel(steps: [])
        mockRepository.addStepResult = .failure(.writeFailed)

        // When
        viewModel.input.addStep.send("날짜 정하기")

        // Then
        XCTAssertTrue(mockLogManager.sentEvents.isEmpty)
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
}
