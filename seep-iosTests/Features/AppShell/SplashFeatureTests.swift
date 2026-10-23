import XCTest

@testable import seep_ios_dev

/// 흰 바탕 로고 스플래시 (#63)
@MainActor
final class SplashFeatureTests: ViewModelTestCase {
    private final class SleepRecorder: @unchecked Sendable {
        var durations: [Duration] = []
    }

    // MARK: GH-63 TC1

    func test_GH63_TC1_대기시간이지나면_goToMain이1번나온다() {
        // Given
        let recorder = SleepRecorder()
        let viewModel = SplashViewModel(dependency: .init(
            holdDuration: .milliseconds(600),
            sleep: { duration in
                recorder.durations.append(duration)
                try? await Task.sleep(for: .milliseconds(50))
            }
        ))

        // When
        viewModel.send(.onAppear)

        // Then — 대기 전에는 넘어가지 않는다
        XCTAssertNil(viewModel.route)
        waitUntil { viewModel.route == .goToMain }
        XCTAssertEqual(recorder.durations, [.milliseconds(600)])
    }

    func test_GH63_TC1_기본대기시간은_0점6초다() {
        // Given / When / Then
        XCTAssertEqual(SplashViewModel.defaultHoldDuration, .milliseconds(600))
    }

    // MARK: GH-63 TC2

    func test_GH63_TC2_onAppear가두번들어와도_goToMain은1번만나온다() {
        // Given
        let recorder = SleepRecorder()
        let viewModel = SplashViewModel(dependency: .init(
            holdDuration: .milliseconds(10),
            sleep: { duration in recorder.durations.append(duration) }
        ))

        // When
        viewModel.send(.onAppear)
        viewModel.send(.onAppear)
        waitUntil { viewModel.route == .goToMain }
        viewModel.send(.routeHandled)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        // Then
        XCTAssertEqual(recorder.durations.count, 1)
        XCTAssertNil(viewModel.route)
    }
}
