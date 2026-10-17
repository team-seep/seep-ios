import Foundation
import Combine

extension SavingInputViewModel {
    struct Input {
        let inputAmountText = PassthroughSubject<String, Never>()
        let didTapQuickAmount = PassthroughSubject<QuickAmount, Never>()
        let didTapSave = PassthroughSubject<Void, Never>()
    }

    struct Output {
        /// 입력 칸에 보일 콤마 문자열 (0 이면 빈 문자열)
        let amountText = CurrentValueSubject<String, Never>("")
        let isSaveEnabled = CurrentValueSubject<Bool, Never>(false)
        /// 지금 금액을 기록하면 어떻게 되는지 (R-4 미리보기)
        let preview: CurrentValueSubject<WishSavingProgress?, Never>
        /// 기록하기 탭. 저장은 상세의 WishSavingsViewModel 이 한다.
        let didSave = PassthroughSubject<Int, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
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

    struct State {
        var amount: Int = 0
    }
}

/// "모은 돈 기록" 바텀시트 (GH-16 R-4).
final class SavingInputViewModel {
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    private var state = State()
    private let config: Config

    init(config: Config) {
        self.config = config
        self.output = Output(preview: .init(Self.makePreview(config: config, amount: 0)))
        bind()
    }

    private func bind() {
        input.inputAmountText
            .withUnretained(self)
            .sink { (owner: SavingInputViewModel, text: String) in
                owner.apply(amount: AmountFormatter.amount(from: text))
            }
            .store(in: &cancellables)

        input.didTapQuickAmount
            .withUnretained(self)
            .sink { (owner: SavingInputViewModel, quickAmount: QuickAmount) in
                owner.applyQuickAmount(quickAmount)
            }
            .store(in: &cancellables)

        input.didTapSave
            .withUnretained(self)
            .sink { (owner: SavingInputViewModel, _) in
                owner.save()
            }
            .store(in: &cancellables)
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
        output.didSave.send(state.amount)
        output.route.send(.dismiss)
    }

    private func apply(amount: Int) {
        state.amount = amount
        output.amountText.send(AmountFormatter.inputText(from: amount))
        output.isSaveEnabled.send(amount > 0)
        output.preview.send(Self.makePreview(config: config, amount: amount))
    }

    private static func makePreview(config: Config, amount: Int) -> WishSavingProgress? {
        return WishSavingProgress(
            targetAmount: config.targetAmount,
            savings: [WishSaving(amount: config.savedAmount + amount)]
        )
    }
}
