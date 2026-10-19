import Foundation
import Combine

extension BadgeCollectionViewModel {
    struct Input {
        let viewWillAppear = PassthroughSubject<Void, Never>()
        let didTapBack = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .badgeCollection
        let badges = CurrentValueSubject<[Badge], Never>([])
        let earnedCount = CurrentValueSubject<Int, Never>(0)
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case pop
    }

    struct State {
        var badges: [Badge] = []
    }

    struct Dependency {
        let wishRepository: WishRepository
        let calendar: Calendar

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            calendar: Calendar = .current
        ) {
            self.wishRepository = wishRepository
            self.calendar = calendar
        }
    }
}

/// 배지 모아보기 (GH-35 R-5). 나타날 때마다 완료 위시로 다시 계산한다.
final class BadgeCollectionViewModel {
    let input = Input()
    let output = Output()
    private var state = State()
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        bind()
    }

    private func bind() {
        input.viewWillAppear
            .withUnretained(self)
            .sink { (owner: BadgeCollectionViewModel, _) in
                owner.reloadBadges()
            }
            .store(in: &cancellables)

        input.didTapBack
            .withUnretained(self)
            .sink { (owner: BadgeCollectionViewModel, _) in
                owner.output.route.send(.pop)
            }
            .store(in: &cancellables)
    }

    private func reloadBadges() {
        let badges = BadgeCalculator.calculate(
            finishedWishes: dependency.wishRepository.fetchAllFinishedWishes(),
            calendar: dependency.calendar
        )
        state.badges = badges
        output.badges.send(badges)
        output.earnedCount.send(badges.filter(\.isEarned).count)
    }
}
