import Foundation
import Observation

extension CompanionWishesViewModel {
    enum Action: Equatable {
        /// 보일 때마다 다시 읽는다 (상세·작성에서 바뀌었을 수 있다)
        case onAppear
        case tapWish(id: String)
        /// 상단 "공유" — 공유 시트는 화면이 연다 (R-7)
        case tapShare
        /// 하단 "…랑 하고 싶은 것 적기" (R-6)
        case tapWrite
        case routeHandled
    }

    struct State: Equatable {
        var person: WishCompanion?
        /// 남은 싶, 세 카테고리 합쳐 D-day 가까운 순 (R-5)
        var remaining: [Wish] = []
        /// 같이 이룬 것, 최근에 이룬 순
        var finished: [Wish] = []

        private var name: String { person?.name ?? "" }
        private var hasFinalConsonant: Bool { WishCompanion.hasFinalConsonant(name) }

        /// "엄마랑 하고 싶은 것" / "지은이랑 하고 싶은 것" (R-9)
        var headline: String {
            hasFinalConsonant
                ? Strings.Companion.Wishes.headlineFinalConsonantFormat(name)
                : Strings.Companion.Wishes.headlineFormat(name)
        }
        var remainingText: String { Strings.Companion.Wishes.remainingFormat(remaining.count) }
        /// 둘째 줄에서 초록으로 칠할 부분
        var remainingHighlight: String { Strings.Companion.Wishes.remainingCountFormat(remaining.count) }
        var finishedTitle: String { Strings.Companion.Wishes.finishedFormat(finished.count) }
        var writeTitle: String {
            hasFinalConsonant
                ? Strings.Companion.Wishes.writeFinalConsonantFormat(name)
                : Strings.Companion.Wishes.writeFormat(name)
        }
    }

    enum Route: Equatable {
        case wishDetail(id: String, isFinished: Bool)
        /// 그 사람이 들어간 작성 화면 (R-6)
        case write(WishCompanion)
    }

    struct Config {
        let personId: String
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

/// 사람별 모아보기 (GH-122 R-5 ~ R-7). 같은 `personId`가 붙은 싶을 세 카테고리 합쳐 남은 것 / 같이 이룬 것으로 보여 준다
@Observable
final class CompanionWishesViewModel {
    let screenName: ScreenName = .companionWishes
    private(set) var state = State()
    private(set) var route: Route?

    private let config: Config
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            reload()
        case .tapWish(let id):
            guard let wish = (state.remaining + state.finished).first(where: { $0.id == id }) else { return }
            route = .wishDetail(id: id, isFinished: wish.isSuccess)
        case .tapShare:
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .companionShare
            ))
        case .tapWrite:
            guard let person = state.person else { return }
            route = .write(person)
        case .routeHandled:
            route = nil
        }
    }

    private func reload() {
        let wishes = dependency.wishRepository.fetchCompanionWishes(personId: config.personId)
        // 이름은 그 사람의 가장 최근 이름. 위시가 모두 지워졌으면 보던 이름을 그대로 둔다
        let latest = dependency.wishRepository.fetchRecentCompanions().first { $0.personId == config.personId }
            ?? wishes.lazy.flatMap(\.companions).first { $0.personId == config.personId }
        if let latest {
            state.person = latest
        }
        state.remaining = wishes.filter { !$0.isSuccess }.sorted(by: Self.deadlineFirst)
        state.finished = wishes.filter(\.isSuccess)
            .sorted { ($0.finishDate ?? .distantPast) > ($1.finishDate ?? .distantPast) }
    }

    /// D-day 가까운 순, 날짜 없는 싶은 뒤(만든 순) (R-5)
    private static func deadlineFirst(_ lhs: Wish, _ rhs: Wish) -> Bool {
        switch (lhs.endDate, rhs.endDate) {
        case let (left?, right?) where left != right:
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            return lhs.createdAt < rhs.createdAt
        }
    }
}
