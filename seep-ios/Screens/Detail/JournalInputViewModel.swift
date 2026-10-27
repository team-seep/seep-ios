import Foundation
import Observation

extension JournalInputViewModel {
    enum Action: Equatable {
        case inputText(String)
        case tapSave
    }

    enum Route: Equatable {
        case dismiss
    }

    struct Config {
        let emoji: String
        let title: String
        /// 오늘. 날짜 라벨에 쓴다
        let date: Date
    }

    struct State: Equatable {
        /// 100자를 넘으면 잘라 둔 값. 입력 칸이 이 값으로 되돌아간다 (R-4)
        var text = ""
        var isSaveEnabled = false

        var countText: String {
            Strings.Detail.Journal.Sheet.countFormat(text.count, WishJournal.maxLength)
        }
    }
}

/// "일지 한 줄 남기기" 시트 (GH-95 R-4). 저장은 상세의 `WishJournalViewModel`이 한다
@Observable
final class JournalInputViewModel: Identifiable {
    let screenName: ScreenName = .journalBottomSheet
    let config: Config
    private(set) var state = State()
    private(set) var route: Route?
    /// 남기기를 누르면 글을 넘긴다
    var onSave: ((String) -> Void)?

    var titlePrefix: String {
        Strings.Detail.Journal.Sheet.titlePrefixFormat(config.emoji)
    }

    var dateText: String {
        DateUtils.toString(format: Strings.Detail.Journal.Sheet.dateFormat, date: config.date)
    }

    init(config: Config) {
        self.config = config
    }

    func send(_ action: Action) {
        switch action {
        case .inputText(let text):
            let limited = String(text.prefix(WishJournal.maxLength))
            state.text = limited
            // 공백뿐이면 남길 수 없다 (R-4, TC-3)
            state.isSaveEnabled = !limited.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .tapSave:
            guard state.isSaveEnabled else { return }
            onSave?(state.text)
            route = .dismiss
        }
    }
}

extension JournalInputViewModel: Equatable {
    static func == (lhs: JournalInputViewModel, rhs: JournalInputViewModel) -> Bool {
        lhs === rhs
    }
}
