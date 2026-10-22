import Foundation
import Combine

extension LegacyYearReviewViewModel {
    struct Input {
        /// 나타날 때마다 다시 집계한다. 목록 → 상세에서 완료 취소하고 돌아온 경우를 반영한다 (R-7)
        let viewWillAppear = PassthroughSubject<Void, Never>()
        /// VC가 카드 영역을 그린 PNG 이미지 (R-5)
        let didTapShare = PassthroughSubject<Data, Never>()
        let didTapShowAll = PassthroughSubject<Void, Never>()
        let didTapClose = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .yearReview
        let summary = CurrentValueSubject<YearReviewSummary?, Never>(nil)
        /// 회고 화면이 닫혔다. 홈이 받아서 목록·배너를 다시 읽는다
        let dismissed = PassthroughSubject<Void, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case presentShareSheet(imageData: Data)
        case pushYearReviewList(LegacyYearReviewListViewModel)
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

/// 올해 이룬 싶 회고 카드 (GH-34 R-3~R-5).
final class LegacyYearReviewViewModel {
    let input = Input()
    let output = Output()
    var cancellables = Set<AnyCancellable>()
    private let config: Config
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        bind()
    }

    private func bind() {
        input.viewWillAppear
            .withUnretained(self)
            .sink { (owner: LegacyYearReviewViewModel, _) in
                owner.loadSummary()
            }
            .store(in: &cancellables)

        input.didTapShare
            .withUnretained(self)
            .sink { (owner: LegacyYearReviewViewModel, imageData: Data) in
                owner.share(imageData: imageData)
            }
            .store(in: &cancellables)

        input.didTapShowAll
            .withUnretained(self)
            .sink { (owner: LegacyYearReviewViewModel, _) in
                owner.pushYearReviewList()
            }
            .store(in: &cancellables)

        input.didTapClose
            .withUnretained(self)
            .sink { (owner: LegacyYearReviewViewModel, _) in
                owner.output.route.send(.dismiss)
                owner.output.dismissed.send(())
            }
            .store(in: &cancellables)
    }

    private func loadSummary() {
        let wishes = LegacyYearReviewViewModel.fetchWishes(
            year: config.year,
            wishRepository: dependency.wishRepository,
            calendar: dependency.calendar
        )
        output.summary.send(YearReviewSummary.make(wishes: wishes, year: config.year, calendar: dependency.calendar))
    }

    private func share(imageData: Data) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: .shareYearReview,
            extraParameters: [.year: config.year]
        ))
        output.route.send(.presentShareSheet(imageData: imageData))
    }

    private func pushYearReviewList() {
        let viewModel = LegacyYearReviewListViewModel(
            config: .init(year: config.year),
            dependency: .init(wishRepository: dependency.wishRepository, calendar: dependency.calendar)
        )
        output.route.send(.pushYearReviewList(viewModel))
    }
}

extension LegacyYearReviewViewModel {
    /// 대상 연도 [1/1, 다음 해 1/1) 의 완료 위시 (R-3)
    static func fetchWishes(year: Int, wishRepository: WishRepository, calendar: Calendar) -> [Wish] {
        guard let range = YearReviewSummary.dateRange(year: year, calendar: calendar) else { return [] }
        return wishRepository.fetchFinishedWishes(from: range.from, to: range.to)
    }
}
