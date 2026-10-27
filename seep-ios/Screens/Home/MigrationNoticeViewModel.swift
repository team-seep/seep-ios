import Foundation
import Observation

extension MigrationNoticeViewModel {
    enum Action: Equatable {
        case onAppear
        case tapRetry
        case tapContact
        case routeHandled
    }

    struct State: Equatable {
        /// nil 이면 카드를 그리지 않는다 (TC-19)
        var problem: LegacyImportProblem?
        var isRetrying = false
        var isContactVisible = false

        var message: String {
            problem == .databaseUnavailable ? Strings.Home.MigrationNotice.messageRestart : Strings.Home.MigrationNotice.message
        }

        /// DB 를 열지 못했으면 실행 중에는 다시 열 수 없어 [다시 시도]를 숨긴다 (R-12)
        var isRetryVisible: Bool {
            if case .importFailed = problem { return true }
            return false
        }
    }

    enum Route: Equatable {
        /// 다시 시도 성공. 홈 목록·위젯을 다시 읽고 토스트를 띄운다 (R-10)
        case restored(toast: String?)
        case toast(String)
        case openURL(URL)
    }

    struct Dependency {
        let recovery: LegacyImportRecovering
        let logManager: LogManagerProtocol
        let contactEmail: String?
        let deviceInfo: DeviceInfo

        init(
            recovery: LegacyImportRecovering = LegacyImportRecovery.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            contactEmail: String? = SettingsLinks.contactEmail,
            deviceInfo: DeviceInfo = .current
        ) {
            self.recovery = recovery
            self.logManager = logManager
            self.contactEmail = contactEmail
            self.deviceInfo = deviceInfo
        }
    }
}

/// 홈 맨 위 "예전 위시를 불러오지 못했어요" 카드 (GH-96 R-9 ~ R-13).
/// 이전 실패 상태에서도 다른 기능은 막지 않는다. 새로 적은 위시는 이전이 끝나면 예전 위시와 같이 남는다
@Observable
final class MigrationNoticeViewModel {
    let screenName: ScreenName = .home
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency
    private var didSendImpression = false

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            refresh()

        case .tapRetry:
            guard state.isRetryVisible, !state.isRetrying else { return }
            sendClickLog(objectId: .migrationRetry)
            state.isRetrying = true
            Task { @MainActor [weak self] in
                guard let self else { return }
                let result = await dependency.recovery.retry()
                finishRetry(result)
            }

        case .tapContact:
            sendClickLog(objectId: .migrationContact)
            if let url = contactURL() {
                route = .openURL(url)
            }

        case .routeHandled:
            route = nil
        }
    }

    private func refresh() {
        state.problem = dependency.recovery.currentProblem()
        state.isContactVisible = contactURL() != nil
        guard state.problem != nil, !didSendImpression else { return }
        didSendImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .card,
            objectId: .migrationNotice
        ))
    }

    private func finishRetry(_ result: Result<Int, Error>) {
        state.isRetrying = false
        switch result {
        case .success(let count):
            state.problem = dependency.recovery.currentProblem()
            // 위젯이 그사이 이전을 끝냈으면 이번에 불러온 수가 0 이라 문구 없이 목록만 다시 읽는다
            route = .restored(toast: count > 0 ? Strings.Home.MigrationNotice.retrySuccessFormat(count) : nil)
        case .failure:
            route = .toast(Strings.Home.MigrationNotice.retryFailure)
        }
    }

    private func contactURL() -> URL? {
        let info = dependency.deviceInfo
        var extraLine: String?
        if case .importFailed(let errorType) = state.problem {
            extraLine = Strings.Home.MigrationNotice.contactErrorFormat(errorType)
        }
        return SettingsLinks.contactMailURL(
            email: dependency.contactEmail,
            appVersion: info.appVersion,
            osVersion: info.osVersion,
            deviceModel: info.deviceModel,
            extraLine: extraLine
        )
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
