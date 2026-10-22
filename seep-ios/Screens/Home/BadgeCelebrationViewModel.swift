import Foundation
import Observation

extension BadgeCelebrationViewModel {
    enum Action: Equatable {
        case onAppear
        case tapConfirm
        case tapViewBadges
    }

    enum Route: Equatable {
        case dismiss
    }

    struct Config {
        /// 이번에 새로 얻은 배지 (배지 정의 순서)
        let badges: [Badge]
        /// 지금까지 완료한 위시 수 (헤드라인 "위시를 n개나 이뤘어요!")
        let finishedCount: Int
    }

    struct Dependency {
        let logManager: LogManagerProtocol

        init(logManager: LogManagerProtocol = LogManager.shared) {
            self.logManager = logManager
        }
    }
}

/// 새 배지 축하 시트 (GH-35 R-6, R-10)
@Observable
final class BadgeCelebrationViewModel {
    let screenName: ScreenName = .badgeBottomSheet
    let badges: [Badge]
    let finishedCount: Int
    private(set) var route: Route?
    /// "배지 모아보기" 탭. 홈이 시트를 닫고 배지 모아보기로 이동한다 (R-10)
    @ObservationIgnored var onViewBadges: (() -> Void)?

    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.badges = config.badges
        self.finishedCount = config.finishedCount
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            let badgeIds = badges.map(\.type.rawValue).joined(separator: ",")
            dependency.logManager.sendEvent(event: ImpressionEvent(
                screen: screenName,
                objectType: .card,
                objectId: .newBadge,
                extraParameters: [.badgeId: badgeIds]
            ))
        case .tapConfirm:
            route = .dismiss
        case .tapViewBadges:
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .viewBadges
            ))
            onViewBadges?()
        }
    }
}
