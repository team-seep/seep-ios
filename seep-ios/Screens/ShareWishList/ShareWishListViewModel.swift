import Foundation
import Observation

extension ShareWishListViewModel {
    enum Action: Equatable {
        /// "D-day 같이 보내기" 토글 (R-6)
        case setIncludesDday(Bool)
        /// "링크 같이 보내기" 토글 (R-6)
        case setIncludesLink(Bool)
        /// 공유 시트(`ShareLink`)를 열었다 (R-7)
        case didTapSend
        case tapClose
        case routeHandled
    }

    struct State: Equatable {
        /// 토글 값은 저장하지 않는다 — 열 때마다 켬 (R-6)
        var includesDday = true
        var includesLink = true
        /// 링크 있는 싶이 없으면 링크 토글을 숨긴다 (R-6)
        var isLinkToggleVisible = false
        var card: ShareWishListCard
        /// 공유 시트에 카드 이미지와 함께 넘기는 글 (R-7)
        var text: String
    }

    enum Route: Equatable {
        case dismiss
    }

    struct Config: Equatable {
        let category: Category
        /// 홈에서 보이던 순서 그대로 (R-4)
        let wishes: [Wish]
    }

    struct Dependency {
        let logManager: LogManagerProtocol
        /// 카드 날짜·D-day 의 "오늘"
        let now: () -> Date
        let calendar: Calendar

        init(
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current
        ) {
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
        }
    }
}

/// 홈 선택 모드에서 고른 싶을 카드 한 장 + 글로 보내는 미리보기 (GH-125 R-2 ~ R-7)
@Observable
final class ShareWishListViewModel {
    let screenName: ScreenName = .shareWishList
    private(set) var state: State
    private(set) var route: Route?

    private let config: Config
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        let isLinkToggleVisible = ShareWishListContent.hasAnyLink(config.wishes)
        let content = Self.makeContent(config: config, dependency: dependency, includesDday: true, includesLink: isLinkToggleVisible)
        self.state = State(isLinkToggleVisible: isLinkToggleVisible, card: content.card, text: content.text)
    }

    func send(_ action: Action) {
        switch action {
        case .setIncludesDday(let isOn):
            guard state.includesDday != isOn else { return }
            state.includesDday = isOn
            rebuild()
        case .setIncludesLink(let isOn):
            guard state.isLinkToggleVisible, state.includesLink != isOn else { return }
            state.includesLink = isOn
            rebuild()
        case .didTapSend:
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .sendWishList,
                extraParameters: [.count: config.wishes.count, .type: sendType]
            ))
        case .tapClose:
            route = .dismiss
        case .routeHandled:
            route = nil
        }
    }

    /// 링크 토글이 숨어 있으면 링크는 보내지 않는 것으로 친다
    private var sendsLink: Bool {
        state.isLinkToggleVisible && state.includesLink
    }

    /// 토글 조합: dday_link / dday / link / none (트래킹 이벤트 표)
    private var sendType: String {
        switch (state.includesDday, sendsLink) {
        case (true, true): return "dday_link"
        case (true, false): return "dday"
        case (false, true): return "link"
        case (false, false): return "none"
        }
    }

    private func rebuild() {
        let content = Self.makeContent(config: config, dependency: dependency, includesDday: state.includesDday, includesLink: sendsLink)
        state.card = content.card
        state.text = content.text
    }

    /// 카드와 글을 같은 "오늘"로 만든다
    private static func makeContent(
        config: Config,
        dependency: Dependency,
        includesDday: Bool,
        includesLink: Bool
    ) -> (card: ShareWishListCard, text: String) {
        let now = dependency.now()
        let card = ShareWishListContent.card(
            category: config.category,
            wishes: config.wishes,
            includesDday: includesDday,
            includesLink: includesLink,
            now: now,
            calendar: dependency.calendar
        )
        let text = ShareWishListContent.text(
            category: config.category,
            wishes: config.wishes,
            includesDday: includesDday,
            includesLink: includesLink,
            now: now,
            calendar: dependency.calendar
        )
        return (card, text)
    }
}
