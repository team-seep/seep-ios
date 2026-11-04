import XCTest

@testable import seep_ios

/// 상세 "단계" 섹션 — 체크/해제만 (GH-5 R-1·R-6, GH-64 TC-606).
/// 작성·수정 화면의 단계 추가·삭제는 `WishStepsViewModelTests`(작성 폼) 쪽에 남는다
final class DetailStepsFeatureTests: ViewModelTestCase {
    private var mockRepository: MockWishRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockWishRepository()
    }

    override func tearDown() {
        mockRepository = nil
        super.tearDown()
    }

    private func makeViewModel(steps: [WishStep]) -> DetailStepsViewModel {
        let wish = Wish(id: "wish-1", emoji: "🏝️", title: "제주도 한 달 살기", steps: steps)
        return DetailStepsViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: mockRepository, logManager: logManager)
        )
    }

    private func makeSteps(count: Int, doneCount: Int = 0) -> [WishStep] {
        (0..<count).map { index in
            WishStep(id: "step-\(index)", title: "단계 \(index)", isDone: index < doneCount, order: index)
        }
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
        viewModel.send(.tapStep(1))

        // Then
        XCTAssertEqual(mockRepository.toggleStepCalls.map(\.stepId), ["step-1"])
        XCTAssertEqual(viewModel.state.progress?.doneCount, 2)
        XCTAssertEqual(viewModel.state.progress?.totalCount, 3)
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
        viewModel.send(.tapStep(1))

        // Then
        XCTAssertEqual(viewModel.state.progress?.doneCount, 2)
        XCTAssertTrue(mockRepository.finishWishCalls.isEmpty)
    }

    // MARK: GH-5 TC22

    func test_GH5_TC22_상세에서는_단계를추가삭제할수없고_추가버튼이비활성이다() {
        // Given 상세 단계 섹션에는 추가·삭제 Action 이 없다 — 범위 밖 행 탭도 무시한다
        let steps = makeSteps(count: 2)
        let viewModel = makeViewModel(steps: steps)

        // When
        viewModel.send(.tapStep(5))

        // Then
        XCTAssertNil(viewModel.route)
        XCTAssertEqual(viewModel.state.steps, steps)
        XCTAssertTrue(mockRepository.toggleStepCalls.isEmpty)
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    func test_GH5_TC22_상세는_수정화면에서돌아온단계로_목록과진행도를갈아끼운다() {
        // Given
        let viewModel = makeViewModel(steps: makeSteps(count: 2))
        let editedSteps = makeSteps(count: 3, doneCount: 1)

        // When
        viewModel.send(.reload(editedSteps))

        // Then
        XCTAssertEqual(viewModel.state.steps, editedSteps)
        XCTAssertEqual(viewModel.state.progress?.doneCount, 1)
        XCTAssertEqual(viewModel.state.progress?.totalCount, 3)
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
        viewModel.send(.tapStep(0))

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
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
        viewModel.send(.tapStep(0))

        // Then
        XCTAssertEqual(logManager.sentEvents.count, 1)
        XCTAssertEqual(logManager.sentEvents.first?.parameters["is_done"] as? Bool, false)
    }

    // MARK: GH-64 TC606

    func test_GH64_TC606_체크저장에실패하면_목록을바꾸지않고_에러알럿을띄운다() {
        // Given
        let steps = makeSteps(count: 2)
        let viewModel = makeViewModel(steps: steps)
        mockRepository.toggleStepResult = .failure(.writeFailed)
        var updates: [[WishStep]] = []
        viewModel.onUpdate = { updates.append($0) }

        // When
        viewModel.send(.tapStep(0))

        // Then
        XCTAssertEqual(viewModel.state.steps, steps)
        XCTAssertTrue(updates.isEmpty)
        guard case .errorAlert = viewModel.route else {
            return XCTFail("에러 알럿 route 가 와야 한다")
        }
    }
}
