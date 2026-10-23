import Foundation
import Observation

extension FutureLetterViewModel {
    enum Action: Equatable {
        case inputLetter(String)
        case tapSeal
        case tapLater
    }

    struct State: Equatable {
        /// 입력 칸에 보일 문자열 (최대 길이로 자른 값)
        var letterText = ""
        var countText = Strings.FutureLetter.countFormat(0, FutureLetterViewModel.maxLength)
        var isSealEnabled = false
    }

    enum Route: Equatable {
        case dismiss
    }

    struct Dependency {
        let logManager: LogManagerProtocol

        init(logManager: LogManagerProtocol = LogManager.shared) {
            self.logManager = logManager
        }
    }
}

/// "이루는 날의 나에게 / 편지를 남겨요" 시트 (GH-61 R-3). 다시 쓰기도 빈 칸에서 시작한다(R-4).
/// 저장은 상세의 `DetailLetterViewModel`이 한다
@Observable
final class FutureLetterViewModel: Identifiable {
    /// 편지 최대 글자 수. 이모지 하나를 한 글자로 센다 (R-3)
    static let maxLength = 300

    let screenName: ScreenName = .futureLetterBottomSheet
    private(set) var state = State()
    private(set) var route: Route?
    /// 봉인하기를 누르면 앞뒤 공백을 뺀 편지를 넘긴다
    @ObservationIgnored var onSeal: ((String) -> Void)?

    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .inputLetter(let text):
            apply(letter: text)
        case .tapSeal:
            seal()
        case .tapLater:
            route = .dismiss
        }
    }

    private func apply(letter: String) {
        let limited = String(letter.prefix(Self.maxLength))
        state.letterText = limited
        state.countText = Strings.FutureLetter.countFormat(limited.count, Self.maxLength)
        state.isSealEnabled = !Self.trimmed(limited).isEmpty
    }

    private func seal() {
        let letter = Self.trimmed(state.letterText)
        guard !letter.isEmpty else { return }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: .sealFutureLetter
        ))
        onSeal?(letter)
        route = .dismiss
    }

    private static func trimmed(_ letter: String) -> String {
        letter.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension FutureLetterViewModel: Equatable {
    static func == (lhs: FutureLetterViewModel, rhs: FutureLetterViewModel) -> Bool {
        lhs === rhs
    }
}
