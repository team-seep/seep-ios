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
        /// 잔디 카드가 화면에 나타남. 노출 로그는 화면당 한 번 (GH-146 TC-13)
        case grassAppeared
        /// 잔디 칸을 누름 → 그날 시트 (GH-146 R-5)
        case tapGrassDay(Date)
        /// 그날 시트의 줄을 누름 → 시트를 닫고 위시 상세 (GH-146 TC-7)
        case tapActivityWish(WishActivity)
        case activityDayDismissed
        /// "기대보다 좋았어요" 요약 카드가 화면에 나타남. 노출 로그는 화면당 한 번 (GH-139 TC-12)
        case expectationSummaryAppeared
        /// 요약 카드 "모아 보기"/"전체 보기" — 목록을 기대보다 좋았던 싶만으로 거르거나 푼다 (GH-139 R-7)
        case tapExpectationBetterFilter
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
        /// 조회 범위 안에 행동이 없으면 nil 이고 카드를 숨긴다 (GH-146 R-6)
        var grass: ActivityGrass?
        /// 열려 있는 그날 시트 (GH-146 R-5)
        var activityDay: ActivityDay?
        /// 기대 비교를 남긴 싶이 3개 미만이면 nil 이고 카드를 숨긴다 (GH-139 R-6)
        var expectationSummary: ExpectationSummary?
        /// "모아 보기"로 기대보다 좋았던 싶만 보는 중. 카테고리 필터와 함께 걸린다 (GH-139 R-7)
        var isBetterFilterOn = false

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

/// 잔디 칸을 눌러 여는 그날 시트 (GH-146 R-5)
struct ActivityDay: Equatable, Identifiable {
    /// 그날 0시
    let date: Date
    /// 시간순 (`WishActivity.chronological`)
    let activities: [WishActivity]

    var id: Date { date }
}

/// 이룬 싶 탭 (GH-64 R-17 ~ R-22, GH-146 잔디, GH-139 기대 비교 요약)
@Observable
final class FinishedViewModel {
    static let recentBadgeLimit = 5

    let screenName: ScreenName = .finished
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency
    private var finishedWishes: [Wish] = []
    private var activitiesByDay: [Date: [WishActivity]] = [:]
    private var didLogGrassImpression = false
    private var didLogExpectationImpression = false

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            reload()

        case .selectFilter(let filter):
            // 카테고리를 바꾸면 모아 보기를 푼다 (GH-139 R-7)
            if filter != state.filter { state.isBetterFilterOn = false }
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

        case .grassAppeared:
            logGrassImpressionOnce()

        case .tapGrassDay(let date):
            openActivityDay(date)

        case .tapActivityWish(let activity):
            sendClickLog(objectId: .activityDayWish)
            state.activityDay = nil
            route = .push(.wishDetail(id: activity.wishId, isFinished: activity.isWishFinished))

        case .activityDayDismissed:
            state.activityDay = nil

        case .expectationSummaryAppeared:
            logExpectationImpressionOnce()

        case .tapExpectationBetterFilter:
            toggleBetterFilter()

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
        reloadGrass()
        state.expectationSummary = ExpectationSummary.make(finishedWishes: finishedWishes)
        // 카드가 사라지면(완료 취소 등으로 3개 미만) 끌 버튼도 없으니 모아 보기를 푼다
        if state.expectationSummary == nil { state.isBetterFilterOn = false }
        rebuildSections()
    }

    private func reloadGrass() {
        let today = dependency.now()
        let calendar = dependency.calendar
        let range = ActivityGrass.fetchRange(today: today, calendar: calendar)
        let activities = dependency.wishRepository.fetchActivities(from: range.from, to: range.to)
        activitiesByDay = Dictionary(grouping: activities) { calendar.startOfDay(for: $0.date) }
        state.grass = activities.isEmpty ? nil : ActivityGrass.make(activities: activities, today: today, calendar: calendar)
        // 시트가 열린 채 다시 읽으면(동기화·다른 열에서 지움) 시트 줄도 새 값으로 맞춘다
        if let openDay = state.activityDay {
            state.activityDay = state.grass == nil
                ? nil
                : ActivityDay(date: openDay.date, activities: (activitiesByDay[openDay.date] ?? []).sorted(by: WishActivity.chronological))
        }
    }

    private func logGrassImpressionOnce() {
        guard state.grass != nil, !didLogGrassImpression else { return }
        didLogGrassImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(screen: screenName, objectType: .card, objectId: .activityGrass))
    }

    private func openActivityDay(_ date: Date) {
        let day = dependency.calendar.startOfDay(for: date)
        guard state.grass != nil, day <= dependency.calendar.startOfDay(for: dependency.now()) else { return }
        let activities = (activitiesByDay[day] ?? []).sorted(by: WishActivity.chronological)
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .card,
            objectId: .activityDay,
            extraParameters: [.count: activities.count]
        ))
        state.activityDay = ActivityDay(date: day, activities: activities)
    }

    private func logExpectationImpressionOnce() {
        guard state.expectationSummary != nil, !didLogExpectationImpression else { return }
        didLogExpectationImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(screen: screenName, objectType: .card, objectId: .expectationSummary))
    }

    private func toggleBetterFilter() {
        guard state.expectationSummary != nil else { return }
        state.isBetterFilterOn.toggle()
        // "모아 보기"를 켤 때만 센다. 끄는 "전체 보기"는 세지 않는다 (TC-12)
        if state.isBetterFilterOn { sendClickLog(objectId: .expectationBetterFilter) }
        rebuildSections()
    }

    private func rebuildSections() {
        let wishes = state.isBetterFilterOn ? finishedWishes.filter { $0.finishFeeling == .better } : finishedWishes
        state.sections = FinishedSectionBuilder.sections(
            finishedWishes: wishes,
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
