import Foundation
import Observation

extension WishSavingsViewModel {
    enum Action: Equatable {
        /// 섹션 "＋ 기록" 탭
        case tapAdd
        /// 기록 시트에서 기록하기
        case saveAmount(Int)
        /// 기록 행의 X 탭 (확인 알럿을 띄운다)
        case tapDelete(savingId: String)
        /// 확인 알럿에서 삭제
        case confirmDelete(savingId: String)
        /// 수정 화면에서 돌아와 목표 금액·카테고리·기록이 바뀌었다
        case reload(Wish)
        case routeHandled
    }

    enum Route: Equatable {
        case savingInput(SavingInputViewModel)
        case deleteAlert(savingId: String)
        case errorAlert(String)
        case toast(String)
    }

    struct Config {
        let wish: Wish
    }

    struct State: Equatable {
        /// 갖고 싶어요 + 목표 금액이 있을 때만 섹션을 보인다 (GH-16 R-1, R-3, R-7)
        var isVisible: Bool
        var progress: WishSavingProgress?
        /// 최신순
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

/// 상세 "모은 돈" 섹션 (GH-16, GH-59 R-6)
@Observable
final class WishSavingsViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?
    /// 저장한 기록 목록. 상세가 위시에 반영한다
    var onUpdate: (([WishSaving]) -> Void)?

    private let wishId: String
    private var category: Category
    private var targetAmount: Int
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        let wish = config.wish
        self.wishId = wish.id
        self.category = wish.category
        self.targetAmount = wish.targetAmount
        self.dependency = dependency
        self.state = State(
            isVisible: Self.isVisible(category: wish.category, targetAmount: wish.targetAmount),
            progress: WishSavingProgress(targetAmount: wish.targetAmount, savings: wish.savings),
            savings: wish.savings
        )
    }

    func send(_ action: Action) {
        switch action {
        case .tapAdd:
            presentSavingInput()
        case .saveAmount(let amount):
            addSaving(amount: amount)
        case .tapDelete(let savingId):
            route = .deleteAlert(savingId: savingId)
        case .confirmDelete(let savingId):
            deleteSaving(savingId: savingId)
        case .reload(let wish):
            category = wish.category
            targetAmount = wish.targetAmount
            apply(savings: wish.savings)
        case .routeHandled:
            route = nil
        }
    }

    private func presentSavingInput() {
        guard let progress = currentProgress else { return }
        sendClickLog(objectId: .addSaving)
        let viewModel = SavingInputViewModel(config: .init(
            targetAmount: progress.targetAmount,
            savedAmount: progress.savedAmount
        ))
        viewModel.onSave = { [weak self] amount in
            self?.send(.saveAmount(amount))
        }
        route = .savingInput(viewModel)
    }

    private func addSaving(amount: Int) {
        guard amount > 0, let before = currentProgress else { return }
        switch dependency.wishRepository.addSaving(wishId: wishId, amount: amount) {
        case .success(let savings):
            apply(savings: savings)
            onUpdate?(savings)
            // 목표 미만 → 이상이 되는 순간에만 한 번 축하한다. 위시를 자동 완료하지는 않는다 (GH-16 R-6)
            if before.isCompleted == false, currentProgress?.isCompleted == true {
                route = .toast(Strings.Detail.Saving.Toast.completed)
            }
            // 금액은 개인정보 성격이라 보내지 않는다
            sendClickLog(objectId: .saveSaving)
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func deleteSaving(savingId: String) {
        switch dependency.wishRepository.deleteSaving(wishId: wishId, savingId: savingId) {
        case .success(let savings):
            apply(savings: savings)
            onUpdate?(savings)
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private var currentProgress: WishSavingProgress? {
        WishSavingProgress(targetAmount: targetAmount, savings: state.savings)
    }

    private func apply(savings: [WishSaving]) {
        state.savings = savings
        state.progress = WishSavingProgress(targetAmount: targetAmount, savings: savings)
        state.isVisible = Self.isVisible(category: category, targetAmount: targetAmount)
    }

    private static func isVisible(category: Category, targetAmount: Int) -> Bool {
        category == .wantToGet && targetAmount > 0
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
