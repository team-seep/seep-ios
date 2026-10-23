import Foundation
import Observation

extension SplashViewModel {
    enum Action: Equatable {
        case onAppear
        case routeHandled
    }

    enum Route: Equatable {
        case goToMain
    }

    struct Dependency {
        /// 로고를 보여 주는 시간 (#63 R-3)
        let holdDuration: Duration
        let sleep: (Duration) async -> Void

        init(
            holdDuration: Duration = SplashViewModel.defaultHoldDuration,
            sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }
        ) {
            self.holdDuration = holdDuration
            self.sleep = sleep
        }
    }
}

/// 흰 바탕 로고 스플래시 (#63). 잠깐 머문 뒤 메인으로 넘어가라고 한 번만 알린다
@MainActor
@Observable
final class SplashViewModel {
    static let defaultHoldDuration: Duration = .milliseconds(600)

    let screenName: ScreenName = .splash
    private(set) var route: Route?

    private let dependency: Dependency
    private var hasStarted = false

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            // 화면이 다시 나타나도 메인으로는 한 번만 보낸다 (#63 TC-2)
            guard !hasStarted else { return }
            hasStarted = true
            Task {
                await dependency.sleep(dependency.holdDuration)
                route = .goToMain
            }

        case .routeHandled:
            route = nil
        }
    }
}
