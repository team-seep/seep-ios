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
        /// 적금 계획 줄 "＋ 계획 세우기"/"변경" (GH-121)
        case tapPlan
        /// 계획 시트에서 "계획 세우기" (GH-121)
        case savePlan(SavingPlan)
        /// 계획 시트에서 "계획 지우기" (GH-121)
        case deletePlan
        case routeHandled
    }

    enum Route: Equatable {
        case savingInput(SavingInputViewModel)
        case savingPlanInput(SavingPlanInputViewModel)
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
        /// 적금 계획 줄. 섹션이 보이고 아직 이루지 않은 위시만 (GH-121 R-1). nil 이면 줄을 그리지 않는다
        var planRow: SavingPlanText.Row?
    }

    struct Dependency {
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        let now: () -> Date
        let calendar: Calendar

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current
        ) {
            self.wishRepository = wishRepository
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
        }
    }
}

/// 상세 "모은 돈" 섹션 (GH-16, GH-59 R-6) + 적금 계획 줄 (GH-121)
@Observable
final class WishSavingsViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?
    /// 저장한 기록 목록. 상세가 위시에 반영한다
    var onUpdate: (([WishSaving]) -> Void)?
    /// 저장한 적금 계획(지우면 nil). 상세가 위시에 반영해 수정 문서로 넘길 값을 맞춘다 (GH-121)
    var onPlanUpdate: ((SavingPlan?) -> Void)?

    /// 섹션이 그리는 위시 값(목표 금액·통화·기록·계획·기한). 저장할 때마다 같이 맞춘다
    private var wish: Wish
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wish = config.wish
        self.dependency = dependency
        self.state = State(isVisible: false, progress: nil, savings: [])
        apply(savings: config.wish.savings)
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
            self.wish = wish
            apply(savings: wish.savings)
        case .tapPlan:
            presentPlanInput()
        case .savePlan(let plan):
            updatePlan(plan)
        case .deletePlan:
            updatePlan(nil)
        case .routeHandled:
            route = nil
        }
    }

    private func presentSavingInput() {
        guard let progress = currentProgress else { return }
        sendClickLog(objectId: .addSaving)
        let viewModel = SavingInputViewModel(config: .init(
            targetAmount: progress.targetAmount,
            savedAmount: progress.savedAmount,
            currency: progress.currency
        ))
        viewModel.onSave = { [weak self] amount in
            self?.send(.saveAmount(amount))
        }
        route = .savingInput(viewModel)
    }

    private func addSaving(amount: Int) {
        guard amount > 0, let before = currentProgress else { return }
        switch dependency.wishRepository.addSaving(wishId: wish.id, amount: amount) {
        case .success(let savings):
            apply(savings: savings)
            onUpdate?(savings)
            updatePlanNotificationIfNeeded()
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
        switch dependency.wishRepository.deleteSaving(wishId: wish.id, savingId: savingId) {
        case .success(let savings):
            apply(savings: savings)
            onUpdate?(savings)
            updatePlanNotificationIfNeeded()
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    // MARK: 적금 계획 (GH-121)

    private func presentPlanInput() {
        guard state.planRow != nil, let progress = currentProgress else { return }
        sendClickLog(objectId: .savingPlan)
        let viewModel = SavingPlanInputViewModel(config: .init(
            plan: wish.savingPlan,
            targetAmount: progress.targetAmount,
            savedAmount: progress.savedAmount,
            savedToday: SavingPlanText.hasSaving(on: dependency.now(), in: state.savings, calendar: dependency.calendar),
            currency: progress.currency,
            now: dependency.now(),
            calendar: dependency.calendar
        ))
        viewModel.onSave = { [weak self] plan in
            self?.send(.savePlan(plan))
        }
        viewModel.onDelete = { [weak self] in
            self?.send(.deletePlan)
        }
        route = .savingPlanInput(viewModel)
    }

    private func updatePlan(_ plan: SavingPlan?) {
        switch dependency.wishRepository.updateSavingPlan(wishId: wish.id, plan: plan) {
        case .success(let saved):
            wish.savingPlan = saved.savingPlan
            apply(savings: state.savings)
            onPlanUpdate?(saved.savingPlan)
            // 저장소가 돌려준 위시는 기록·제목까지 최신이라 그대로 알림을 맞춘다 (R-6)
            dependency.notificationManager.updateSavingPlanNotification(wish: saved)
            if plan != nil {
                // 금액은 개인정보 성격이라 보내지 않는다
                sendClickLog(objectId: .saveSavingPlan)
            }
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    /// 기록으로 목표에 닿았거나(알림 지움) 기록을 지워 다시 모자라면(다시 예약) 넣는 날 알림을 맞춘다 (R-6)
    private func updatePlanNotificationIfNeeded() {
        guard wish.savingPlan != nil else { return }
        dependency.notificationManager.updateSavingPlanNotification(wish: wish)
    }

    private var currentProgress: WishSavingProgress? {
        WishSavingProgress(targetAmount: wish.targetAmount, savings: state.savings, currency: wish.currency)
    }

    private func apply(savings: [WishSaving]) {
        wish.savings = savings
        state.savings = savings
        state.progress = currentProgress
        state.isVisible = wish.category == .wantToGet && wish.targetAmount > 0
        state.planRow = makePlanRow()
    }

    private func makePlanRow() -> SavingPlanText.Row? {
        guard state.isVisible, !wish.isSuccess, let progress = state.progress else { return nil }
        // 이미 다 모았으면 새 계획을 세울 일이 없다. 있던 계획은 바꾸거나 지울 수 있게 줄을 남긴다
        if progress.isCompleted, wish.savingPlan == nil { return nil }
        return SavingPlanText.row(
            plan: wish.savingPlan,
            savings: state.savings,
            remainingAmount: progress.remainingAmount,
            currency: wish.currency,
            deadline: wish.endDate,
            now: dependency.now(),
            calendar: dependency.calendar
        )
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
