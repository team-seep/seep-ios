import Foundation
import Combine

extension WishStepsViewModel {
    struct Input {
        let didTapAdd = PassthroughSubject<Void, Never>()
        let addStep = PassthroughSubject<String, Never>()
        let didTapStep = PassthroughSubject<Int, Never>()
        let deleteStep = PassthroughSubject<Int, Never>()
        /// 상세: 수정 화면에서 돌아와 위시가 바뀌면 단계 목록을 갈아끼운다.
        let reloadSteps = PassthroughSubject<[WishStep], Never>()
    }

    struct Output {
        let screenName: ScreenName
        let steps: CurrentValueSubject<[WishStep], Never>
        let progress: CurrentValueSubject<WishStepProgress?, Never>
        let isAddEnabled: CurrentValueSubject<Bool, Never>
        /// 단계 목록이 바뀔 때마다 보낸다. 상세는 위시에 반영해 홈까지 전달하고, 작성·수정은 Reactor 상태에 담는다.
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
        /// 위시 상세: 체크/해제만 하고, 바뀔 때마다 Repository 에 바로 저장한다. 추가·삭제는 하지 않는다 (R-1).
        case persisted(Wish)
        /// 위시 작성·수정: 추가·삭제만 하고 저장하지 않는다. 작성/수정 완료 때 위시와 함께 저장된다 (R-13, R-18).
        case draft(steps: [WishStep], screenName: ScreenName)
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

/// 위시 상세·작성·수정의 "단계" 섹션. 두 화면 모두 레거시 Reactor 라 이 섹션만 Combine ViewModel 로 붙인다.
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
            isAddEnabled: .init(config.mode.canEdit && steps.count < WishStep.maxCount)
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

        input.reloadSteps
            .withUnretained(self)
            .sink { (owner: WishStepsViewModel, steps: [WishStep]) in
                owner.apply(steps: steps)
            }
            .store(in: &cancellables)
    }

    private func presentAddStepInputIfPossible() {
        guard config.mode.canEdit else { return }
        guard state.steps.count < WishStep.maxCount else {
            output.toast.send(Strings.Detail.Step.Toast.maxCount)
            return
        }
        output.route.send(.presentAddStepInput)
    }

    private func addStep(title: String) {
        guard config.mode.canEdit else { return }
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

        let result: Result<[WishStep], RepositoryError> = .success(
            state.steps + [WishStep(title: trimmedTitle, order: state.steps.count)]
        )

        if handleResult(result) {
            sendClickLog(objectId: .addStep)
        }
    }

    private func toggleStep(index: Int) {
        // 체크는 상세에서만 한다 (R-1). 작성·수정 화면에서는 체크하지 않는다 (R-13, R-18).
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
        guard config.mode.canEdit, state.steps.indices.contains(index) else { return }
        let step = state.steps[index]

        let remainingSteps = state.steps.filter { $0.id != step.id }
        handleResult(.success(remainingSteps.enumerated().map { order, step in
            WishStep(id: step.id, title: step.title, isDone: step.isDone, order: order)
        }))
    }

    /// 저장 결과를 State·Output 에 반영한다. 성공하면 true.
    @discardableResult
    private func handleResult(_ result: Result<[WishStep], RepositoryError>) -> Bool {
        switch result {
        case .success(let steps):
            apply(steps: steps)
            output.didUpdateSteps.send(steps)
            return true
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
            return false
        }
    }

    private func apply(steps: [WishStep]) {
        state.steps = steps
        output.steps.send(steps)
        output.progress.send(config.mode.showsProgress ? WishStepProgress(steps: steps) : nil)
        output.isAddEnabled.send(config.mode.canEdit && steps.count < WishStep.maxCount)
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
        case .draft(let steps, _):
            return steps
        }
    }

    var screenName: ScreenName {
        switch self {
        case .persisted:
            return .wishDetail
        case .draft(_, let screenName):
            return screenName
        }
    }

    /// 진행도는 상세에서만 보여준다 (R-6, R-13).
    var showsProgress: Bool {
        if case .persisted = self { return true }
        return false
    }

    /// 추가·삭제는 작성·수정 화면에서만 한다 (R-1, R-18).
    var canEdit: Bool {
        if case .draft = self { return true }
        return false
    }
}
