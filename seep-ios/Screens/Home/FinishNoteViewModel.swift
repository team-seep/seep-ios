import Foundation
import Observation

extension FinishNoteViewModel {
    enum Action: Equatable {
        case onAppear
        case inputNote(String)
        /// 기대 비교 세 칸. 고른 칸을 다시 누르면 선택을 푼다 (GH-139 R-2)
        case selectFeeling(FinishFeeling)
        case tapSave
        case tapSkip
        /// "＋ 이어서 적기" — 입력한 소감은 저장하고 닫은 뒤 작성 화면을 연다 (GH-84 R-1)
        case tapChainNext
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
        /// 고른 기대 비교. nil 이면 고르지 않음 (GH-139 R-2)
        var selectedFeeling: FinishFeeling?
        /// 소감이나 기대 비교 중 하나라도 있으면 켠다 (GH-139 R-3)
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

/// 완료 직후 "기대했던 것과 비교하면 어땠어요?" 세 칸 + 한 줄 소감 시트 (GH-25 R-1~R-3, GH-139 R-2~R-4)
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
    /// 이어서 적을 앞 위시. 시트가 닫힌 뒤 홈이 작성 화면을 연다 (GH-84 R-1)
    @ObservationIgnored var onChainNext: ((Wish) -> Void)?

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
        case .selectFeeling(let feeling):
            select(feeling: feeling)
        case .tapSave:
            save()
        case .tapSkip:
            sendClickLog(objectId: .skipFinishNote)
            route = .dismiss
        case .tapChainNext:
            chainNext()
        }
    }

    private func apply(note: String) {
        let limited = String(note.prefix(Self.maxLength))
        state.noteText = limited
        state.countText = Strings.Home.FinishNote.countFormat(limited.count, Self.maxLength)
        updateSaveEnabled()
    }

    private func select(feeling: FinishFeeling) {
        if state.selectedFeeling == feeling {
            state.selectedFeeling = nil
        } else {
            state.selectedFeeling = feeling
            // 고를 때만 남긴다. 푸는 동작은 세지 않는다 (TC-11)
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .selectExpectation,
                extraParameters: [.expectation: feeling.rawValue]
            ))
        }
        updateSaveEnabled()
    }

    private func updateSaveEnabled() {
        state.isSaveEnabled = hasInput
    }

    /// 저장할 것이 있는지: 공백을 자른 소감이나 고른 기대 비교 (R-3)
    private var hasInput: Bool {
        !Self.trimmed(state.noteText).isEmpty || state.selectedFeeling != nil
    }

    private func save() {
        guard hasInput else { return }
        let note = Self.trimmed(state.noteText)

        switch dependency.wishRepository.updateFinishNote(wishId: wish.id, note: note, feeling: state.selectedFeeling) {
        case .success(let savedWish):
            sendClickLog(objectId: .saveFinishNote)
            onSave?(savedWish)
            route = .dismiss
        case .failure(let error):
            route = .errorAlert(message: error.localizedDescription)
        }
    }

    /// 소감·기대 비교가 있으면 저장하고(실패하면 이어 적지 않는다), 없으면 건너뛰기와 같다 (GH-84 R-1, GH-139 R-3)
    private func chainNext() {
        let note = Self.trimmed(state.noteText)
        var previous = wish
        if hasInput {
            switch dependency.wishRepository.updateFinishNote(wishId: wish.id, note: note, feeling: state.selectedFeeling) {
            case .success(let savedWish):
                onSave?(savedWish)
                previous = savedWish
            case .failure(let error):
                route = .errorAlert(message: error.localizedDescription)
                return
            }
        }
        sendClickLog(objectId: .chainNextWish)
        onChainNext?(previous)
        route = .dismiss
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
            DisplayDate.monthDay(sealedAt)
        )
        return OpenedLetter(headline: headline, caption: caption, body: wish.futureLetter)
    }

    private static func trimmed(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
