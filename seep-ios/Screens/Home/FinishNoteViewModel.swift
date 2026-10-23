import Foundation
import Observation

extension FinishNoteViewModel {
    enum Action: Equatable {
        case onAppear
        case inputNote(String)
        case tapSave
        case tapSkip
    }

    /// 완료 순간 열리는 "미래의 나에게" 편지 (GH-61 R-5)
    struct OpenedLetter: Equatable {
        /// "{n}일 전의 내가\n편지를 보냈어요" (n = 완료일 - 봉인일, 0이면 "오늘의 내가")
        let headline: String
        /// "{이모지} {제목} · {M월 d일}에 씀"
        let caption: String
        let body: String
    }

    struct State: Equatable {
        /// 편지가 있으면 시트 위쪽에 연다. 없으면 지금 소감 시트 그대로 (R-5, TC-8)
        var openedLetter: OpenedLetter?
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
        let now: () -> Date
        let calendar: Calendar

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
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
        state.openedLetter = Self.openedLetter(wish: config.wish, now: dependency.now(), calendar: dependency.calendar)
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            dependency.logManager.sendEvent(event: ImpressionEvent(
                screen: screenName,
                objectType: .card,
                objectId: .finishNoteSheet
            ))
            if state.openedLetter != nil {
                dependency.logManager.sendEvent(event: ImpressionEvent(
                    screen: screenName,
                    objectType: .card,
                    objectId: .futureLetter
                ))
            }
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

    private static func openedLetter(wish: Wish, now: Date, calendar: Calendar) -> OpenedLetter? {
        guard wish.hasFutureLetter, let sealedAt = wish.futureLetterSealedAt else { return nil }
        let finishedAt = wish.finishDate ?? now
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: sealedAt),
            to: calendar.startOfDay(for: finishedAt)
        ).day ?? 0
        let headline = days > 0
            ? Strings.Home.FinishNote.letterTitleFormat(days)
            : Strings.Home.FinishNote.letterTitleToday
        let caption = Strings.Home.FinishNote.letterCardFormat(
            "\(wish.emoji) \(wish.title)".trimmingCharacters(in: .whitespaces),
            DateUtils.toString(format: "M월 d일", date: sealedAt)
        )
        return OpenedLetter(headline: headline, caption: caption, body: wish.futureLetter)
    }

    private static func trimmed(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
