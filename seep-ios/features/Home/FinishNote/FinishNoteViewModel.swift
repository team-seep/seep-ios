import Foundation
import Combine

extension FinishNoteViewModel {
    struct Input {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let inputNote = PassthroughSubject<String, Never>()
        let didTapSave = PassthroughSubject<Void, Never>()
        let didTapSkip = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .finishNoteBottomSheet
        let wish: Wish
        /// 입력 칸에 보일 문자열 (최대 길이로 자른 값)
        let noteText = CurrentValueSubject<String, Never>("")
        let countText = CurrentValueSubject<String, Never>(Strings.Home.FinishNote.countFormat(0, FinishNoteViewModel.maxLength))
        let isSaveEnabled = CurrentValueSubject<Bool, Never>(false)
        /// 저장에 성공한 위시. 홈 목록이 받아서 셀을 갱신한다.
        let didSaveNote = PassthroughSubject<Wish, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case dismiss
        case showErrorAlert(Error)
    }

    struct Config {
        let wish: Wish
    }

    struct State {
        var note: String = ""
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

/// 완료 직후 "이루고 나니 어때요?" 한 줄 소감 바텀시트 (GH-25 R-1~R-3).
final class FinishNoteViewModel {
    /// 소감 최대 글자 수. 이모지 하나를 한 글자로 센다 (R-2)
    static let maxLength = 40

    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    private var state = State()
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.output = Output(wish: config.wish)
        self.dependency = dependency
        bind()
    }

    private func bind() {
        input.viewDidLoad
            .withUnretained(self)
            .sink { (owner: FinishNoteViewModel, _) in
                owner.sendImpressionLog()
            }
            .store(in: &cancellables)

        input.inputNote
            .withUnretained(self)
            .sink { (owner: FinishNoteViewModel, text: String) in
                owner.apply(note: text)
            }
            .store(in: &cancellables)

        input.didTapSave
            .withUnretained(self)
            .sink { (owner: FinishNoteViewModel, _) in
                owner.save()
            }
            .store(in: &cancellables)

        input.didTapSkip
            .withUnretained(self)
            .sink { (owner: FinishNoteViewModel, _) in
                owner.sendClickLog(objectId: .skipFinishNote)
                owner.output.route.send(.dismiss)
            }
            .store(in: &cancellables)
    }

    private func apply(note: String) {
        let limited = String(note.prefix(Self.maxLength))
        state.note = limited
        output.noteText.send(limited)
        output.countText.send(Strings.Home.FinishNote.countFormat(limited.count, Self.maxLength))
        output.isSaveEnabled.send(!Self.trimmed(limited).isEmpty)
    }

    private func save() {
        let note = Self.trimmed(state.note)
        guard !note.isEmpty else { return }

        switch dependency.wishRepository.updateFinishNote(wishId: output.wish.id, note: note) {
        case .success(let wish):
            sendClickLog(objectId: .saveFinishNote)
            output.didSaveNote.send(wish)
            output.route.send(.dismiss)
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }

    private func sendImpressionLog() {
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .finishNoteSheet
        ))
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId
        ))
    }

    private static func trimmed(_ note: String) -> String {
        return note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
