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
        let screenName: ScreenName = .wishDetail
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
        let wish: Wish
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

/// 위시 상세의 "단계" 섹션. 상세 화면은 레거시 Reactor 라 이 섹션만 Combine ViewModel 로 붙인다.
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
        self.state = State(steps: config.wish.steps)
        self.output = Output(
            steps: .init(config.wish.steps),
            progress: .init(WishStepProgress(steps: config.wish.steps)),
            isAddEnabled: .init(config.wish.steps.count < WishStep.maxCount)
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

        let result = dependency.wishRepository.addStep(wishId: config.wish.id, title: trimmedTitle)
        if handleResult(result) {
            sendClickLog(objectId: .addStep)
        }
    }

    private func toggleStep(index: Int) {
        guard state.steps.indices.contains(index) else { return }
        let step = state.steps[index]

        let result = dependency.wishRepository.toggleStep(wishId: config.wish.id, stepId: step.id)
        if handleResult(result),
           let toggledStep = state.steps.first(where: { $0.id == step.id }) {
            sendClickLog(objectId: .checkStep, extraParameters: [.isDone: toggledStep.isDone])
        }
    }

    private func deleteStep(index: Int) {
        guard state.steps.indices.contains(index) else { return }
        let step = state.steps[index]

        let result = dependency.wishRepository.deleteStep(wishId: config.wish.id, stepId: step.id)
        handleResult(result)
    }

    /// 저장 결과를 State·Output 에 반영한다. 성공하면 true.
    @discardableResult
    private func handleResult(_ result: Result<[WishStep], RepositoryError>) -> Bool {
        switch result {
        case .success(let steps):
            state.steps = steps
            output.steps.send(steps)
            output.progress.send(WishStepProgress(steps: steps))
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
