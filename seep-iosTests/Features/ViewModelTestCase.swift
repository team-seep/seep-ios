import XCTest
import Observation

@testable import seep_ios

/// 화면별 기능 테스트(GH-64 R-44)의 공용 바탕.
/// SwiftUI ViewModel(`@Observable`, `send(_:)` → `state`/`route`)을 같은 방식으로 단언한다
class ViewModelTestCase: XCTestCase {
    var logManager: MockLogManager!

    override func setUp() {
        super.setUp()
        logManager = MockLogManager()
        // 시뮬레이터에서 앱 안 언어를 바꿔 뒀어도 문구 단언은 원문(ko) 기준이다 (GH-103 R-21)
        AppLanguage.shared.select(nil)
    }

    override func tearDown() {
        logManager = nil
        super.tearDown()
    }

    /// 비동기 Action 결과처럼 나중에 바뀌는 값을 기다린다. 조건이 시간 안에 참이 되지 않으면 실패한다
    func waitUntil(
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: @escaping () -> Bool
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertTrue(condition(), "시간 안에 조건이 참이 되지 않았다", file: file, line: line)
    }

    /// `@Observable` 프로퍼티를 읽는 클로저가 바뀌었는지 알려 준다. View 가 다시 그려지는지 확인할 때 쓴다
    func observeChange(of read: @escaping () -> Void) -> () -> Bool {
        let flag = ChangeFlag()
        withObservationTracking(read) { flag.isChanged = true }
        return { flag.isChanged }
    }

    /// 보낸 클릭 로그 중 object_id 가 같은 것
    func clickEvents(objectId: LogObjectId) -> [any LogEventType] {
        logManager.sentEvents.filter { event in
            event.name == .click && (event.extraParameters?[.objectId] as? LogObjectId) == objectId
        }
    }
}

private final class ChangeFlag: @unchecked Sendable {
    var isChanged = false
}

// MARK: GH-64 TC40

/// 헬퍼 자체 검증용 ViewModel (R9 구조의 최소 예)
@Observable
private final class SampleCounterViewModel {
    enum Action {
        case increment
        case incrementLater
    }

    struct State: Equatable {
        var count = 0
    }

    enum Route: Equatable {
        case reachedThree
    }

    private(set) var state = State()
    private(set) var route: Route?

    func send(_ action: Action) {
        switch action {
        case .increment:
            increment()
        case .incrementLater:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.increment()
            }
        }
    }

    private func increment() {
        state.count += 1
        if state.count == 3 {
            route = .reachedThree
        }
    }
}

final class ViewModelTestCaseTests: ViewModelTestCase {
    func test_GH64_TC40_send하면_state가바뀌고_조건이되면_route가기록된다() {
        // Given
        let viewModel = SampleCounterViewModel()
        let didChange = observeChange { _ = viewModel.state }

        // When
        viewModel.send(.increment)
        viewModel.send(.increment)
        viewModel.send(.increment)

        // Then
        XCTAssertEqual(viewModel.state.count, 3)
        XCTAssertEqual(viewModel.route, .reachedThree)
        XCTAssertTrue(didChange())
    }

    func test_GH64_TC40_비동기Action은_waitUntil로_기다린다() {
        // Given
        let viewModel = SampleCounterViewModel()

        // When
        viewModel.send(.incrementLater)

        // Then
        XCTAssertEqual(viewModel.state.count, 0)
        waitUntil { viewModel.state.count == 1 }
    }
}
