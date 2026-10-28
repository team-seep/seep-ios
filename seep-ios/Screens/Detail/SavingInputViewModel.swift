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
        /// 금액의 통화. 입력 소수 자릿수·빠른 금액이 통화를 따른다 (GH-103)
        var currency: String = AmountFormatter.krw
    }

    struct State: Equatable {
        var amount = 0
        /// 입력 칸에 보일 문자열 (0 이면 빈 문자열). 소수가 있는 통화는 치는 중인 소수점을 남긴다
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
            let input = AmountFormatter.input(text, currency: config.currency)
            apply(amount: input.amount, text: input.text)
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

    /// 빠른 금액 버튼(최소 단위). 원화는 +1만·+5만·+10만
    var quickAmounts: [Int] {
        AmountFormatter.quickAmounts(currency: config.currency)
    }

    var currency: String {
        config.currency
    }

    private func apply(amount: Int, text: String? = nil) {
        state.amount = amount
        state.amountText = text ?? AmountFormatter.inputText(from: amount, currency: config.currency)
        state.isSaveEnabled = amount > 0
        state.preview = Self.makePreview(config: config, amount: amount)
    }

    private static func makePreview(config: Config, amount: Int) -> WishSavingProgress? {
        WishSavingProgress(
            targetAmount: config.targetAmount,
            savings: [WishSaving(amount: config.savedAmount + amount)],
            currency: config.currency
        )
    }
}

extension SavingInputViewModel: Equatable {
    static func == (lhs: SavingInputViewModel, rhs: SavingInputViewModel) -> Bool {
        lhs === rhs
    }
}
