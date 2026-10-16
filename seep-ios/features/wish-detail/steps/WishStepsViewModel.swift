import Foundation
import Combine

extension WishStepsViewModel {
    struct Input {
        let didTapAdd = PassthroughSubject<Void, Never>()
        let addStep = PassthroughSubject<String, Never>()
        let didTapStep = PassthroughSubject<Int, Never>()
        let deleteStep = PassthroughSubject<Int, Never>()
    }

    struct Output {
        let screenName: ScreenName
        let steps: CurrentValueSubject<[WishStep], Never>
        let progress: CurrentValueSubject<WishStepProgress?, Never>
        let isAddEnabled: CurrentValueSubject<Bool, Never>
        /// 저장된 단계 목록이 바뀔 때마다 보낸다. 상세 화면이 위시에 반영해 홈까지 전달한다.
        let didUpdateSteps = PassthroughSubject<[WishStep], Never>()
        let toast = PassthroughSubject<String, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case presentAddStepInput
        case showErrorAlert(Error)
    }

    struct Config {
        let mode: Mode
    }

    enum Mode {
        /// 위시 상세: 바뀔 때마다 Repository 에 바로 저장한다.
        case persisted(Wish)
        /// 위시 작성: 저장하지 않고 화면 상태로만 들고 있다가, 작성 완료 때 위시와 함께 저장된다.
        case draft
    }

    struct State {
        var steps: [WishStep]
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

/// 위시 상세·작성의 "단계" 섹션. 두 화면 모두 레거시 Reactor 라 이 섹션만 Combine ViewModel 로 붙인다.
final class WishStepsViewModel {
    let input = Input()
    let output: Output
    private var state: State
    private let config: Config
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        let steps = config.mode.initialSteps
        self.state = State(steps: steps)
        self.output = Output(
            screenName: config.mode.screenName,
            steps: .init(steps),
            progress: .init(config.mode.showsProgress ? WishStepProgress(steps: steps) : nil),
            isAddEnabled: .init(steps.count < WishStep.maxCount)
        )

        bind()
    }

    private func bind() {
        input.didTapAdd
            .withUnretained(self)
            .sink { (owner: WishStepsViewModel, _) in
                owner.presentAddStepInputIfPossible()
            }
            .store(in: &cancellables)

        input.addStep
            .withUnretained(self)
            .sink { (owner: WishStepsViewModel, title: String) in
                owner.addStep(title: title)
            }
            .store(in: &cancellables)

        input.didTapStep
            .withUnretained(self)
            .sink { (owner: WishStepsViewModel, index: Int) in
                owner.toggleStep(index: index)
            }
            .store(in: &cancellables)

        input.deleteStep
            .withUnretained(self)
            .sink { (owner: WishStepsViewModel, index: Int) in
                owner.deleteStep(index: index)
            }
            .store(in: &cancellables)
    }

    private func presentAddStepInputIfPossible() {
        guard state.steps.count < WishStep.maxCount else {
            output.toast.send(Strings.Detail.Step.Toast.maxCount)
            return
        }
        output.route.send(.presentAddStepInput)
    }

    private func addStep(title: String) {
        guard state.steps.count < WishStep.maxCount else {
            output.toast.send(Strings.Detail.Step.Toast.maxCount)
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else { return }
        guard trimmedTitle.count <= WishStep.maxTitleLength else {
            output.toast.send(Strings.Detail.Step.Toast.maxLength)
            return
        }

        let result: Result<[WishStep], RepositoryError>
        switch config.mode {
        case .persisted(let wish):
            result = dependency.wishRepository.addStep(wishId: wish.id, title: trimmedTitle)
        case .draft:
            result = .success(state.steps + [WishStep(title: trimmedTitle, order: state.steps.count)])
        }

        if handleResult(result) {
            sendClickLog(objectId: .addStep)
        }
    }

    private func toggleStep(index: Int) {
        // 작성 중에는 체크하지 않는다 (R-13). 모든 단계는 미완료로 만들어진다.
        guard case .persisted(let wish) = config.mode,
              state.steps.indices.contains(index) else { return }
        let step = state.steps[index]

        let result = dependency.wishRepository.toggleStep(wishId: wish.id, stepId: step.id)
        if handleResult(result),
           let toggledStep = state.steps.first(where: { $0.id == step.id }) {
            sendClickLog(objectId: .checkStep, extraParameters: [.isDone: toggledStep.isDone])
        }
    }

    private func deleteStep(index: Int) {
        guard state.steps.indices.contains(index) else { return }
        let step = state.steps[index]

        let result: Result<[WishStep], RepositoryError>
        switch config.mode {
        case .persisted(let wish):
            result = dependency.wishRepository.deleteStep(wishId: wish.id, stepId: step.id)
        case .draft:
            let remainingSteps = state.steps.filter { $0.id != step.id }
            result = .success(remainingSteps.enumerated().map { order, step in
                WishStep(id: step.id, title: step.title, isDone: step.isDone, order: order)
            })
        }
        handleResult(result)
    }

    /// 저장 결과를 State·Output 에 반영한다. 성공하면 true.
    @discardableResult
    private func handleResult(_ result: Result<[WishStep], RepositoryError>) -> Bool {
        switch result {
        case .success(let steps):
            state.steps = steps
            output.steps.send(steps)
            output.progress.send(config.mode.showsProgress ? WishStepProgress(steps: steps) : nil)
            output.isAddEnabled.send(steps.count < WishStep.maxCount)
            output.didUpdateSteps.send(steps)
            return true
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
            return false
        }
    }

    private func sendClickLog(objectId: LogObjectId, extraParameters: [ParameterName: Any]? = nil) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId,
            extraParameters: extraParameters
        ))
    }
}

private extension WishStepsViewModel.Mode {
    var initialSteps: [WishStep] {
        switch self {
        case .persisted(let wish):
            return wish.steps
        case .draft:
            return []
        }
    }

    var screenName: ScreenName {
        switch self {
        case .persisted:
            return .wishDetail
        case .draft:
            return .write
        }
    }

    /// 작성 화면에서는 진행도를 숨긴다 (R-13).
    var showsProgress: Bool {
        if case .persisted = self { return true }
        return false
    }
}
