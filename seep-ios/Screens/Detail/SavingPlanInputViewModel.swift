import Foundation
import Observation

extension SavingPlanInputViewModel {
    enum Action: Equatable {
        case selectCycle(SavingPlan.Cycle)
        /// 매주면 요일(`Calendar` weekday), 매달이면 날짜
        case selectDay(Int)
        case inputAmountText(String)
        case tapSave
        /// 계획이 있을 때 "계획 지우기"
        case tapDelete
        /// 계획이 없을 때 "다음에 할게요"
        case tapLater
    }

    enum Route: Equatable {
        case dismiss
    }

    struct Config {
        /// 지금 계획. 있으면 그 값으로 채워 열고 "계획 지우기"를 보인다 (R-2)
        let plan: SavingPlan?
        let targetAmount: Int
        let savedAmount: Int
        var currency: String = AmountFormatter.krw
        let now: Date
        let calendar: Calendar
    }

    struct State: Equatable {
        var cycle: SavingPlan.Cycle
        /// 매주 요일(`Calendar` weekday 1=일요일)
        var weekday: Int
        /// 매달 날짜(1~31)
        var monthDay: Int
        var amount = 0
        /// 입력 칸에 보일 문자열 (0 이면 빈 문자열)
        var amountText = ""
        var isSaveEnabled = false
        /// 지금 값으로 저장하면 언제 다 모이는지. 이미 다 모았거나 금액이 없으면 nil (R-3)
        var preview: Preview?

        /// 매달 29~31일이면 "그 날짜가 없는 달은 마지막 날로 셀게요"
        var showsMonthEndNotice: Bool {
            cycle == .monthly && monthDay > 28
        }
    }

    struct Preview: Equatable {
        let text: String
        /// `text` 안에서 굵게 칠할 날짜
        let highlight: String
    }
}

/// 적금 계획 시트 (GH-121 R-2). 저장·지우기는 상세의 `WishSavingsViewModel`이 한다
@Observable
final class SavingPlanInputViewModel: Identifiable {
    private(set) var state: State
    private(set) var route: Route?
    /// "계획 세우기"를 누르면 계획을 넘긴다
    var onSave: ((SavingPlan) -> Void)?
    /// "계획 지우기"
    var onDelete: (() -> Void)?

    private let config: Config

    init(config: Config) {
        self.config = config
        let today = config.calendar.dateComponents([.weekday, .day], from: config.now)
        let plan = config.plan
        var state = State(
            cycle: plan?.cycle ?? .weekly,
            weekday: plan?.cycle == .weekly ? plan?.day ?? 1 : today.weekday ?? 1,
            monthDay: plan?.cycle == .monthly ? plan?.day ?? 1 : today.day ?? 1
        )
        if let plan {
            state.amount = plan.amount
            state.amountText = AmountFormatter.inputText(from: plan.amount, currency: config.currency)
        }
        self.state = state
        refresh()
    }

    var currency: String {
        config.currency
    }

    var calendar: Calendar {
        config.calendar
    }

    var isDeletable: Bool {
        config.plan != nil
    }

    func send(_ action: Action) {
        switch action {
        case .selectCycle(let cycle):
            state.cycle = cycle
            refresh()
        case .selectDay(let day):
            guard SavingPlan.dayRange(state.cycle).contains(day) else { return }
            switch state.cycle {
            case .weekly: state.weekday = day
            case .monthly: state.monthDay = day
            }
            refresh()
        case .inputAmountText(let text):
            let input = AmountFormatter.input(text, currency: config.currency)
            // 상한(`WishSaving.maxAmount`)을 넘기는 입력은 AmountFormatter 가 받지 않는다
            state.amount = input.amount
            state.amountText = input.text
            refresh()
        case .tapSave:
            guard let plan = currentPlan else { return }
            onSave?(plan)
            route = .dismiss
        case .tapDelete:
            guard isDeletable else { return }
            onDelete?()
            route = .dismiss
        case .tapLater:
            route = .dismiss
        }
    }

    /// 지금 고른 값으로 만든 계획. 금액이 0 이면 nil
    private var currentPlan: SavingPlan? {
        SavingPlan(
            cycle: state.cycle,
            day: state.cycle == .weekly ? state.weekday : state.monthDay,
            amount: state.amount
        )
    }

    private func refresh() {
        let plan = currentPlan
        state.isSaveEnabled = plan != nil
        state.preview = plan.flatMap { plan in
            SavingPlanForecast(
                plan: plan,
                remainingAmount: max(config.targetAmount - config.savedAmount, 0),
                deadline: nil,
                now: config.now,
                calendar: config.calendar
            )
        }.map { forecast in
            let sentence = SavingPlanText.forecastSentence(forecast, now: config.now, calendar: config.calendar)
            return Preview(text: sentence.text, highlight: sentence.highlight)
        }
    }
}

extension SavingPlanInputViewModel: Equatable {
    static func == (lhs: SavingPlanInputViewModel, rhs: SavingPlanInputViewModel) -> Bool {
        lhs === rhs
    }
}
