import Foundation
import Observation

extension FinishedViewModel {
    enum Action: Equatable {
        /// 탭이 보일 때마다. 다른 곳(위젯·상세)에서 바뀐 완료 상태를 다시 읽는다 (TC-203)
        case onAppear
        case selectFilter(Category?)
        case tapWish(id: String)
        case tapSearch
        case tapBadgeCollection
        case tapYearReview
        case routeHandled
    }

    struct State: Equatable {
        /// 세 카테고리를 합친 이룬 싶 수 (R-17)
        var totalCount = 0
        var filter: Category?
        var sections: [FinishedSection] = []
        var earnedBadgeCount = 0
        /// 최근에 얻은 배지부터 최대 5개 (R-18)
        var recentBadges: [BadgeType] = []
        var yearReview: YearReviewEligibility?

        var isEmpty: Bool { totalCount == 0 }
        /// 이룬 싶은 있는데 고른 카테고리에만 없을 때 (R-22)
        var isFilteredEmpty: Bool { totalCount > 0 && sections.isEmpty }
    }

    enum Route: Equatable {
        case push(AppDestination)
        case yearReview(year: Int)
    }

    struct Dependency {
        let wishRepository: WishRepository
        let remoteConfigRepository: RemoteConfigRepository
        let logManager: LogManagerProtocol
        let now: () -> Date
        let calendar: Calendar

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            remoteConfigRepository: RemoteConfigRepository = RemoteConfigRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current
        ) {
            self.wishRepository = wishRepository
            self.remoteConfigRepository = remoteConfigRepository
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
        }
    }
}

/// 이룬 싶 탭 (GH-64 R-17 ~ R-22)
@Observable
final class FinishedViewModel {
    static let recentBadgeLimit = 5

    let screenName: ScreenName = .finished
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency
    private var finishedWishes: [Wish] = []

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            reload()

        case .selectFilter(let filter):
            state.filter = filter
            rebuildSections()

        case .tapWish(let id):
            route = .push(.wishDetail(id: id, isFinished: true))

        case .tapSearch:
            route = .push(.search(finishedOnly: true))

        case .tapBadgeCollection:
            sendClickLog(objectId: .badgeCollection)
            route = .push(.badgeCollection)

        case .tapYearReview:
            guard let yearReview = state.yearReview else { return }
            sendClickLog(objectId: .yearReviewCard, extraParameters: [.year: yearReview.year])
            route = .yearReview(year: yearReview.year)

        case .routeHandled:
            route = nil
        }
    }

    private func reload() {
        finishedWishes = dependency.wishRepository.fetchAllFinishedWishes().filter(\.isSuccess)
        state.totalCount = finishedWishes.count

        let badges = BadgeCalculator.calculate(finishedWishes: finishedWishes, calendar: dependency.calendar)
        let earned = badges.filter(\.isEarned)
        state.earnedBadgeCount = earned.count
        state.recentBadges = earned
            .sorted { ($0.earnedDate ?? .distantPast) > ($1.earnedDate ?? .distantPast) }
            .prefix(Self.recentBadgeLimit)
            .map(\.type)

        // 카드에는 닫기가 없어 닫은 연도와 상관없이 기간이면 보인다 (R-18)
        state.yearReview = YearReviewEligibility.make(
            remoteConfigRepository: dependency.remoteConfigRepository,
            wishRepository: dependency.wishRepository,
            now: dependency.now(),
            calendar: dependency.calendar
        )
        rebuildSections()
    }

    private func rebuildSections() {
        state.sections = FinishedSectionBuilder.sections(
            finishedWishes: finishedWishes,
            filter: state.filter,
            calendar: dependency.calendar
        )
    }

    private func sendClickLog(objectId: LogObjectId, extraParameters: [ParameterName: Any]? = nil) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId,
            extraParameters: extraParameters
        ))
    }
}
