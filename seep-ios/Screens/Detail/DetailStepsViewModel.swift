import Foundation
import Observation

extension DetailStepsViewModel {
    enum Action: Equatable {
        /// 단계 행 탭 — 체크/해제 (GH-5 R-1)
        case tapStep(Int)
        /// 수정 화면에서 돌아와 단계가 바뀌었다
        case reload([WishStep])
        case routeHandled
    }

    enum Route: Equatable {
        case errorAlert(String)
    }

    struct Config {
        let wish: Wish
    }

    struct State: Equatable {
        var steps: [WishStep]
        var progress: WishStepProgress?
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
        }
    }
}

/// 상세 "단계 n/m" 섹션 (GH-5, GH-59 R-6). 체크/해제만 하고 바로 저장한다. 추가·삭제는 수정 화면에서 (R-1)
@Observable
final class DetailStepsViewModel {
    private(set) var state: State
    private(set) var route: Route?
    /// 저장한 단계 목록. 상세가 위시에 반영한다
    var onUpdate: (([WishStep]) -> Void)?

    private let wishId: String
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wishId = config.wish.id
        self.dependency = dependency
        self.state = State(steps: config.wish.steps, progress: WishStepProgress(steps: config.wish.steps))
    }

    func send(_ action: Action) {
        switch action {
        case .tapStep(let index):
            toggleStep(index: index)
        case .reload(let steps):
            apply(steps: steps)
        case .routeHandled:
            route = nil
        }
    }

    private func toggleStep(index: Int) {
        guard state.steps.indices.contains(index) else { return }
        let step = state.steps[index]
        switch dependency.wishRepository.toggleStep(wishId: wishId, stepId: step.id) {
        case .success(let steps):
            apply(steps: steps)
            onUpdate?(steps)
            if let toggledStep = steps.first(where: { $0.id == step.id }) {
                dependency.logManager.sendEvent(event: ClickEvent(
                    screen: .wishDetail,
                    objectType: .button,
                    objectId: .checkStep,
                    extraParameters: [.isDone: toggledStep.isDone]
                ))
            }
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func apply(steps: [WishStep]) {
        state.steps = steps
        state.progress = WishStepProgress(steps: steps)
    }
}
