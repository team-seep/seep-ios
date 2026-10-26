import Foundation
import Observation

extension WishJournalViewModel {
    enum Action: Equatable {
        /// 섹션 "＋ 남기기" 또는 빈 줄 "＋ 오늘 한 줄 남기기" 탭
        case tapAdd
        /// 입력 시트에서 남기기
        case saveText(String)
        /// "모두 보기 (n)" 탭 — 이 자리에서 전부 펼친다
        case tapViewAll
        /// 줄 길게 누르기 메뉴 "지우기"
        case tapDelete(journalId: String)
        /// 상세가 위시를 다시 읽었다
        case reload(Wish)
        case routeHandled
    }

    enum Route: Equatable {
        case journalInput(JournalInputViewModel)
        case errorAlert(String)
        case toast(String)
    }

    struct Config {
        let wish: Wish
        /// 홈에서 연 상세만 남기기·지우기를 할 수 있다. 이룬 싶 상세는 보기 전용 (R-3, R-7)
        let isEditable: Bool
    }

    struct State: Equatable {
        /// 최신순
        var journals: [WishJournal]
        var isEditable: Bool
        var isExpanded = false

        /// 접혀 있으면 최신 3개만 (R-3)
        var visibleJournals: [WishJournal] {
            isExpanded ? journals : Array(journals.prefix(WishJournalViewModel.collapsedCount))
        }

        var isViewAllVisible: Bool {
            !isExpanded && journals.count > WishJournalViewModel.collapsedCount
        }
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol
        let now: () -> Date

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
            self.now = now
        }
    }
}

/// 상세 "일지" 섹션 (GH-95). 이루는 동안 날짜별로 한 줄씩 남긴다
@Observable
final class WishJournalViewModel {
    static let collapsedCount = 3

    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?
    /// 일지를 남기거나 지웠다. 상세가 위시(일지·점검 시각)를 다시 읽는다
    var onUpdate: (() -> Void)?

    private let wishId: String
    private var emoji: String
    private var title: String
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.wishId = config.wish.id
        self.emoji = config.wish.emoji
        self.title = config.wish.title
        self.dependency = dependency
        self.state = State(journals: config.wish.journals, isEditable: config.isEditable)
    }

    func send(_ action: Action) {
        switch action {
        case .tapAdd:
            presentInput()
        case .saveText(let text):
            addJournal(text: text)
        case .tapViewAll:
            guard state.isViewAllVisible else { return }
            sendClickLog(screen: screenName, objectId: .viewAllJournals)
            state.isExpanded = true
        case .tapDelete(let journalId):
            deleteJournal(journalId: journalId)
        case .reload(let wish):
            emoji = wish.emoji
            title = wish.title
            state.journals = wish.journals
        case .routeHandled:
            route = nil
        }
    }

    private func presentInput() {
        guard state.isEditable else { return }
        sendClickLog(screen: screenName, objectId: .addJournal)
        let viewModel = JournalInputViewModel(config: .init(emoji: emoji, title: title, date: dependency.now()))
        viewModel.onSave = { [weak self] text in
            self?.send(.saveText(text))
        }
        route = .journalInput(viewModel)
    }

    private func addJournal(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard state.isEditable, !trimmed.isEmpty else { return }
        switch dependency.wishRepository.addJournal(wishId: wishId, text: String(trimmed.prefix(WishJournal.maxLength))) {
        case .success(let journals):
            state.journals = journals
            onUpdate?()
            // 글은 개인 기록이라 보내지 않는다
            sendClickLog(screen: .journalBottomSheet, objectId: .saveJournal)
            route = .toast(Strings.Detail.Journal.Toast.saved)
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func deleteJournal(journalId: String) {
        guard state.isEditable else { return }
        switch dependency.wishRepository.deleteJournal(wishId: wishId, journalId: journalId) {
        case .success(let journals):
            state.journals = journals
            onUpdate?()
        case .failure(let error):
            route = .errorAlert(error.localizedDescription)
        }
    }

    private func sendClickLog(screen: ScreenName, objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screen,
            objectType: .button,
            objectId: objectId
        ))
    }
}
