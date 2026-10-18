import Foundation
import Combine

extension BadgeCelebrationViewModel {
    struct Input {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let didTapConfirm = PassthroughSubject<Void, Never>()
        let didTapViewBadges = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .badgeBottomSheet
        let badges: [Badge]
        let finishedCount: Int
        /// "배지 모아보기" 탭. 홈이 시트를 닫고 배지 모아보기로 push 한다 (R-10)
        let didTapViewBadges = PassthroughSubject<Void, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
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

/// 새 배지 축하 바텀시트 (GH-35 R-6, R-10).
final class BadgeCelebrationViewModel {
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.output = Output(badges: config.badges, finishedCount: config.finishedCount)
        self.dependency = dependency
        bind()
    }

    private func bind() {
        input.viewDidLoad
            .withUnretained(self)
            .sink { (owner: BadgeCelebrationViewModel, _) in
                owner.sendImpressionLog()
            }
            .store(in: &cancellables)

        input.didTapConfirm
            .withUnretained(self)
            .sink { (owner: BadgeCelebrationViewModel, _) in
                owner.output.route.send(.dismiss)
            }
            .store(in: &cancellables)

        input.didTapViewBadges
            .withUnretained(self)
            .sink { (owner: BadgeCelebrationViewModel, _) in
                owner.sendClickLog(objectId: .viewBadges)
                owner.output.didTapViewBadges.send(())
            }
            .store(in: &cancellables)
    }

    private func sendImpressionLog() {
        let badgeIds = output.badges.map(\.type.rawValue).joined(separator: ",")
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .newBadge,
            extraParameters: [.badgeId: badgeIds]
        ))
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
