import Foundation
import Observation

extension YearReviewViewModel {
    enum Action: Equatable {
        /// 나타날 때마다 다시 집계한다. 목록 → 상세에서 완료 취소하고 돌아온 경우를 반영한다 (GH-34 R-7)
        case onAppear
        /// 공유 시트(`ShareLink`)를 열었다 (GH-34 R-5)
        case didTapShare
        case tapShowAll
        case tapClose
        case routeHandled
    }

    struct State: Equatable {
        var summary: YearReviewSummary?
    }

    enum Route: Equatable {
        case yearReviewList(year: Int)
        case dismiss
    }

    struct Config {
        let year: Int
    }

    struct Dependency {
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol
        let calendar: Calendar

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared,
            calendar: Calendar = .current
        ) {
            self.wishRepository = wishRepository
            self.logManager = logManager
            self.calendar = calendar
        }
    }
}

/// 올해 이룬 싶 회고 카드 (GH-34 R-3~R-5)
@Observable
final class YearReviewViewModel {
    let screenName: ScreenName = .yearReview
    let year: Int
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.year = config.year
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            let wishes = Self.fetchWishes(year: year, wishRepository: dependency.wishRepository, calendar: dependency.calendar)
            state.summary = YearReviewSummary.make(wishes: wishes, year: year, calendar: dependency.calendar)
        case .didTapShare:
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .shareYearReview,
                extraParameters: [.year: year]
            ))
        case .tapShowAll:
            route = .yearReviewList(year: year)
        case .tapClose:
            route = .dismiss
        case .routeHandled:
            route = nil
        }
    }
}

extension YearReviewViewModel {
    /// 대상 연도 [1/1, 다음 해 1/1) 의 완료 위시 (GH-34 R-3)
    static func fetchWishes(year: Int, wishRepository: WishRepository, calendar: Calendar) -> [Wish] {
        guard let range = YearReviewSummary.dateRange(year: year, calendar: calendar) else { return [] }
        return wishRepository.fetchFinishedWishes(from: range.from, to: range.to)
    }
}
