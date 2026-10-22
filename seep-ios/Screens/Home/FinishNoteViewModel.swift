import Foundation
import Observation

extension FinishNoteViewModel {
    enum Action: Equatable {
        case onAppear
        case inputNote(String)
        case tapSave
        case tapSkip
    }

    struct State: Equatable {
        /// 입력 칸에 보일 문자열 (최대 길이로 자른 값)
        var noteText = ""
        var countText = Strings.Home.FinishNote.countFormat(0, FinishNoteViewModel.maxLength)
        var isSaveEnabled = false
    }

    enum Route: Equatable {
        case dismiss
        case errorAlert(message: String)
    }

    struct Config {
        let wish: Wish
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

/// 완료 직후 "이루고 나니 어때요?" 한 줄 소감 시트 (GH-25 R-1~R-3)
@Observable
final class FinishNoteViewModel {
    /// 소감 최대 글자 수. 이모지 하나를 한 글자로 센다 (R-2)
    static let maxLength = 40

    let screenName: ScreenName = .finishNoteBottomSheet
    let wish: Wish
    private(set) var state = State()
    private(set) var route: Route?
    /// 저장에 성공한 위시. 홈 목록이 받아서 셀을 갱신한다
    @ObservationIgnored var onSave: ((Wish) -> Void)?

    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wish = config.wish
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            dependency.logManager.sendEvent(event: ImpressionEvent(
                screen: screenName,
                objectType: .card,
                objectId: .finishNoteSheet
            ))
        case .inputNote(let text):
            apply(note: text)
        case .tapSave:
            save()
        case .tapSkip:
            sendClickLog(objectId: .skipFinishNote)
            route = .dismiss
        }
    }

    private func apply(note: String) {
        let limited = String(note.prefix(Self.maxLength))
        state.noteText = limited
        state.countText = Strings.Home.FinishNote.countFormat(limited.count, Self.maxLength)
        state.isSaveEnabled = !Self.trimmed(limited).isEmpty
    }

    private func save() {
        let note = Self.trimmed(state.noteText)
        guard !note.isEmpty else { return }

        switch dependency.wishRepository.updateFinishNote(wishId: wish.id, note: note) {
        case .success(let savedWish):
            sendClickLog(objectId: .saveFinishNote)
            onSave?(savedWish)
            route = .dismiss
        case .failure(let error):
            route = .errorAlert(message: error.localizedDescription)
        }
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId
        ))
    }

    private static func trimmed(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
