import Foundation

/// 체크 위젯(GH-48)의 체크 원을 눌렀을 때 할 일. 위젯 인텐트와 테스트가 같이 쓰도록 순수 함수로 둔다 (R-11)
enum WidgetCheckAction: Equatable {
    /// 첫 미완료 단계를 완료로
    case checkStep(id: String)
    /// (남은 단계가 있으면 그 단계까지 완료하고) 위시를 완료로
    case finishWish(lastStepId: String?)

    /// 미완료 단계가 2개 이상 남았으면 다음 단계 체크, 1개 남았거나 없으면 위시 완료 (R-3)
    static func make(wish: Wish) -> WidgetCheckAction {
        let remainingSteps = sortedSteps(wish).filter { !$0.isDone }
        if remainingSteps.count >= 2 {
            return .checkStep(id: remainingSteps[0].id)
        }
        return .finishWish(lastStepId: remainingSteps.first?.id)
    }

    /// 줄의 보조 문구 (R-2, R-4)
    static func caption(wish: Wish) -> String {
        if wish.isSuccess {
            return Strings.Widget.Check.Caption.finished
        }
        let steps = sortedSteps(wish)
        guard let nextStep = steps.first(where: { !$0.isDone }) else {
            return Strings.Widget.Check.Caption.finish
        }
        let doneCount = steps.filter(\.isDone).count
        return Strings.Widget.Check.Caption.nextStepFormat(nextStep.title, doneCount + 1, steps.count)
    }

    private static func sortedSteps(_ wish: Wish) -> [WishStep] {
        return wish.steps.sorted { $0.order < $1.order }
    }
}
