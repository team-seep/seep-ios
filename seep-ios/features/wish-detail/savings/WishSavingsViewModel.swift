import Foundation
import Combine

extension WishSavingsViewModel {
    struct Input {
        /// "＋ 모은 돈 기록" 탭
        let didTapAdd = PassthroughSubject<Void, Never>()
        /// 바텀시트에서 기록하기
        let saveAmount = PassthroughSubject<Int, Never>()
        /// 기록 행의 X 탭 (확인 알럿을 띄운다)
        let didTapDelete = PassthroughSubject<String, Never>()
        /// 확인 알럿에서 삭제
        let confirmDelete = PassthroughSubject<String, Never>()
        /// 수정 화면에서 돌아와 위시가 바뀌면 목표 금액·카테고리·기록을 갈아끼운다.
        let reloadWish = PassthroughSubject<Wish, Never>()
    }

    struct Output {
        let screenName: ScreenName = .wishDetail
        /// 갖고 싶어요 + 목표 금액이 있을 때만 섹션을 보인다 (R-1, R-3, R-7)
        let isVisible: CurrentValueSubject<Bool, Never>
        let progress: CurrentValueSubject<WishSavingProgress?, Never>
        /// 최신순
        let savings: CurrentValueSubject<[WishSaving], Never>
        /// 기록이 바뀔 때마다 보낸다. 상세 Reactor 의 위시에 반영해 수정 화면·홈까지 전달한다.
        let didUpdateSavings = PassthroughSubject<[WishSaving], Never>()
        let toast = PassthroughSubject<String, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case presentSavingInput(SavingInputViewModel)
        case showDeleteAlert(savingId: String)
        case showErrorAlert(Error)
    }

    struct Config {
        let wish: Wish
    }

    struct State {
        let wishId: String
        var category: Category
        var targetAmount: Int
        var savings: [WishSaving]
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

/// 위시 상세의 "모으기" 섹션 (GH-16). 상세 화면은 레거시 Reactor 라 #5 단계 섹션처럼 이 섹션만 Combine ViewModel 로 붙인다.
final class WishSavingsViewModel {
    let input = Input()
    let output: Output
    private var state: State
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    init(config: Config, dependency: Dependency = Dependency()) {
        self.dependency = dependency
        let wish = config.wish
        self.state = State(
            wishId: wish.id,
            category: wish.category,
            targetAmount: wish.targetAmount,
            savings: wish.savings
        )
        self.output = Output(
            isVisible: .init(Self.isVisible(category: wish.category, targetAmount: wish.targetAmount)),
            progress: .init(WishSavingProgress(targetAmount: wish.targetAmount, savings: wish.savings)),
            savings: .init(wish.savings)
        )

        bind()
    }

    private func bind() {
        input.didTapAdd
            .withUnretained(self)
            .sink { (owner: WishSavingsViewModel, _) in
                owner.presentSavingInput()
            }
            .store(in: &cancellables)

        input.saveAmount
            .withUnretained(self)
            .sink { (owner: WishSavingsViewModel, amount: Int) in
                owner.addSaving(amount: amount)
            }
            .store(in: &cancellables)

        input.didTapDelete
            .withUnretained(self)
            .sink { (owner: WishSavingsViewModel, savingId: String) in
                owner.output.route.send(.showDeleteAlert(savingId: savingId))
            }
            .store(in: &cancellables)

        input.confirmDelete
            .withUnretained(self)
            .sink { (owner: WishSavingsViewModel, savingId: String) in
                owner.deleteSaving(savingId: savingId)
            }
            .store(in: &cancellables)

        input.reloadWish
            .withUnretained(self)
            .sink { (owner: WishSavingsViewModel, wish: Wish) in
                owner.state.category = wish.category
                owner.state.targetAmount = wish.targetAmount
                owner.apply(savings: wish.savings)
            }
            .store(in: &cancellables)
    }

    private func presentSavingInput() {
        guard let progress = currentProgress else { return }
        sendClickLog(objectId: .addSaving)

        let viewModel = SavingInputViewModel(config: .init(
            targetAmount: progress.targetAmount,
            savedAmount: progress.savedAmount
        ))
        viewModel.output.didSave
            .subscribe(input.saveAmount)
            .store(in: &viewModel.cancellables)
        output.route.send(.presentSavingInput(viewModel))
    }

    private func addSaving(amount: Int) {
        guard amount > 0, let before = currentProgress else { return }

        switch dependency.wishRepository.addSaving(wishId: state.wishId, amount: amount) {
        case .success(let savings):
            apply(savings: savings)
            output.didUpdateSavings.send(savings)
            // 목표 미만 → 이상이 되는 순간에만 한 번 축하한다. 위시를 자동 완료하지는 않는다 (R-6).
            if before.isCompleted == false, currentProgress?.isCompleted == true {
                output.toast.send(Strings.Detail.Saving.Toast.completed)
            }
            // 금액은 개인정보 성격이라 보내지 않는다
            sendClickLog(objectId: .saveSaving)
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }

    private func deleteSaving(savingId: String) {
        switch dependency.wishRepository.deleteSaving(wishId: state.wishId, savingId: savingId) {
        case .success(let savings):
            apply(savings: savings)
            output.didUpdateSavings.send(savings)
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }

    private var currentProgress: WishSavingProgress? {
        WishSavingProgress(targetAmount: state.targetAmount, savings: state.savings)
    }

    private func apply(savings: [WishSaving]) {
        state.savings = savings
        output.savings.send(savings)
        output.progress.send(currentProgress)
        output.isVisible.send(Self.isVisible(category: state.category, targetAmount: state.targetAmount))
    }

    private static func isVisible(category: Category, targetAmount: Int) -> Bool {
        return category == .wantToGet && targetAmount > 0
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
