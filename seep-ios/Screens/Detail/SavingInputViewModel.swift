import Foundation
import Observation

extension SavingInputViewModel {
    enum Action: Equatable {
        case inputAmountText(String)
        case tapQuickAmount(QuickAmount)
        case tapSave
    }

    enum Route: Equatable {
        case dismiss
    }

    enum QuickAmount: Equatable {
        /// 입력 금액에 더한다 (+1만 / +5만 / +10만)
        case plus(Int)
        /// 남은 금액으로 바꾼다
        case remainingAll
    }

    struct Config {
        let targetAmount: Int
        let savedAmount: Int
    }

    struct State: Equatable {
        var amount = 0
        /// 입력 칸에 보일 콤마 문자열 (0 이면 빈 문자열)
        var amountText = ""
        var isSaveEnabled = false
        /// 지금 금액을 기록하면 어떻게 되는지 (GH-16 R-4 미리보기)
        var preview: WishSavingProgress?
    }
}

/// "모은 돈 기록" 시트 (GH-16 R-4). 저장은 상세의 `WishSavingsViewModel`이 한다
@Observable
final class SavingInputViewModel: Identifiable {
    private(set) var state: State
    private(set) var route: Route?
    /// 기록하기를 누르면 금액을 넘긴다
    var onSave: ((Int) -> Void)?

    private let config: Config

    init(config: Config) {
        self.config = config
        self.state = State(preview: Self.makePreview(config: config, amount: 0))
    }

    func send(_ action: Action) {
        switch action {
        case .inputAmountText(let text):
            apply(amount: AmountFormatter.amount(from: text))
        case .tapQuickAmount(let quickAmount):
            applyQuickAmount(quickAmount)
        case .tapSave:
            save()
        }
    }

    private func applyQuickAmount(_ quickAmount: QuickAmount) {
        switch quickAmount {
        case .plus(let amount):
            apply(amount: min(state.amount + amount, WishSaving.maxAmount))
        case .remainingAll:
            apply(amount: max(config.targetAmount - config.savedAmount, 0))
        }
    }

    private func save() {
        guard state.amount > 0 else { return }
        onSave?(state.amount)
        route = .dismiss
    }

    private func apply(amount: Int) {
        state.amount = amount
        state.amountText = AmountFormatter.inputText(from: amount)
        state.isSaveEnabled = amount > 0
        state.preview = Self.makePreview(config: config, amount: amount)
    }

    private static func makePreview(config: Config, amount: Int) -> WishSavingProgress? {
        WishSavingProgress(
            targetAmount: config.targetAmount,
            savings: [WishSaving(amount: config.savedAmount + amount)]
        )
    }
}

extension SavingInputViewModel: Equatable {
    static func == (lhs: SavingInputViewModel, rhs: SavingInputViewModel) -> Bool {
        lhs === rhs
    }
}
