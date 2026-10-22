import Foundation
import Observation

extension BadgeCollectionViewModel {
    enum Action: Equatable {
        /// 나타날 때마다 완료 위시로 다시 계산한다 (완료 취소하고 돌아온 경우)
        case onAppear
    }

    struct State: Equatable {
        var badges: [Badge] = []
        var earnedCount = 0
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

/// 배지 모아보기 (GH-35 R-5)
@Observable
final class BadgeCollectionViewModel {
    let screenName: ScreenName = .badgeCollection
    private(set) var state = State()

    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            reloadBadges()
        }
    }

    private func reloadBadges() {
        let badges = BadgeCalculator.calculate(
            finishedWishes: dependency.wishRepository.fetchAllFinishedWishes(),
            calendar: dependency.calendar
        )
        state = State(badges: badges, earnedCount: badges.filter(\.isEarned).count)
    }
}
