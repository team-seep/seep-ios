import Foundation
import Observation

/// SwiftUI `scenePhase`를 ViewModel 이 SwiftUI 를 모르게 옮긴 값 (R2)
enum AppLifecyclePhase: Equatable {
    case active
    case inactive
    case background
}

extension AppLockOverlayViewModel {
    enum Action: Equatable {
        /// 스플래시가 끝나고 메인이 뜰 때 (콜드 스타트, GH-46 R-5 ①)
        case mainDidAppear
        case phaseChanged(AppLifecyclePhase)
        case tapUnlock
    }

    enum LockState: Equatable {
        case unlocked
        /// 앱 전환기 스냅샷용 덮개. 버튼 없이 가리기만 한다 (GH-46 R-7)
        case covered
        /// 인증해야 열리는 잠금 화면 (GH-46 R-6)
        case locked
    }

    struct State: Equatable {
        var lockState: LockState = .unlocked
        var description = ""
        var unlockButtonTitle = ""
    }

    struct Dependency {
        let preference: Preference
        let authenticationManager: AuthenticationManagerProtocol
        let logManager: LogManagerProtocol
        let now: () -> Date

        init(
            preference: Preference = .shared,
            authenticationManager: AuthenticationManagerProtocol = AuthenticationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init
        ) {
            self.preference = preference
            self.authenticationManager = authenticationManager
            self.logManager = logManager
            self.now = now
        }
    }
}

/// `.appLockOverlay()`가 루트와 모든 시트 위에 그리는 잠금 상태 (GH-64 A-8).
/// 판정 규칙은 GH-46 `AppLockViewModel`과 같고, UIKit 생명주기 알림 대신 `scenePhase` 전이로 받는다
@Observable
final class AppLockOverlayViewModel {
    let screenName: ScreenName = .appLock
    private(set) var state = State()

    private let dependency: Dependency
    /// 스플래시 전에는 생명주기로 잠그지 않는다. 콜드 스타트는 메인이 뜰 때 잠근다
    private var hasShownMain = false
    private var phase: AppLifecyclePhase = .active
    /// 잠길 때 한 번만 자동으로 인증을 요청한다. 인증 창이 닫히며 다시 활성화돼도 또 묻지 않는다 (GH-46 R-6)
    private var needsAutoAuthentication = false

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .mainDidAppear:
            hasShownMain = true
            // 콜드 스타트는 지난 백그라운드 시각과 상관없이 잠근다
            guard isLockAvailable else { return }
            lock()

        case .phaseChanged(let newPhase):
            let oldPhase = phase
            phase = newPhase
            handlePhaseChange(from: oldPhase, to: newPhase)

        case .tapUnlock:
            authenticate()
        }
    }

    private func handlePhaseChange(from oldPhase: AppLifecyclePhase, to newPhase: AppLifecyclePhase) {
        switch (oldPhase, newPhase) {
        case (.active, .inactive):
            coverIfNeeded()
        case (_, .background):
            dependency.preference.appLockBackgroundAt = dependency.now()
            coverIfNeeded()
        case (.background, .inactive):
            // 앞으로 돌아오는 중 (UIKit willEnterForeground)
            lockIfNeeded()
        case (_, .active):
            if oldPhase == .background {
                lockIfNeeded()
            }
            handleDidBecomeActive()
        default:
            break
        }
    }

    /// 잠금을 켰고 인증할 수 있을 때만 잠근다. 기기 암호를 지워 인증이 불가능하면 영영 못 열게 되므로 잠그지 않는다 (GH-46 R-11)
    private var isLockAvailable: Bool {
        dependency.preference.isAppLockEnabled && dependency.authenticationManager.canAuthenticate()
    }

    private func coverIfNeeded() {
        guard hasShownMain,
              dependency.preference.isAppLockEnabled,
              state.lockState == .unlocked,
              // 잠금 끄기 등 앱이 띄운 인증 창 때문에 비활성화될 때는 덮지 않는다 (GH-46 R-7)
              !dependency.authenticationManager.isAuthenticating else { return }
        updateTexts()
        state.lockState = .covered
    }

    private func lockIfNeeded() {
        guard hasShownMain, isLockAvailable, state.lockState != .locked else { return }
        let shouldLock = AppLockPolicy.shouldLock(
            lastBackgroundAt: dependency.preference.appLockBackgroundAt,
            now: dependency.now(),
            isEnabled: true
        )
        guard shouldLock else { return }
        lock()
    }

    private func lock() {
        updateTexts()
        needsAutoAuthentication = true
        state.lockState = .locked
        // 콜드 스타트처럼 이미 활성 상태면 바로 묻는다. 아니면 활성화될 때 묻는다
        if phase == .active {
            authenticateAutomaticallyIfNeeded()
        }
    }

    private func handleDidBecomeActive() {
        switch state.lockState {
        case .covered:
            // 60초 안에 돌아왔다 (GH-46 R-7)
            state.lockState = .unlocked
        case .locked:
            authenticateAutomaticallyIfNeeded()
        case .unlocked:
            break
        }
    }

    private func authenticateAutomaticallyIfNeeded() {
        guard needsAutoAuthentication else { return }
        needsAutoAuthentication = false
        authenticate()
    }

    private func authenticate() {
        guard state.lockState == .locked,
              !dependency.authenticationManager.isAuthenticating else { return }

        dependency.authenticationManager.authenticate(reason: Strings.AppLock.reason) { [weak self] isSuccess in
            guard let self, isSuccess else { return }
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .unlockApp
            ))
            state.lockState = .unlocked
        }
    }

    private func updateTexts() {
        let biometryName = dependency.authenticationManager.biometry().name
        state.description = Strings.AppLock.Screen.descriptionFormat(biometryName)
        state.unlockButtonTitle = Strings.AppLock.Screen.unlockButtonFormat(biometryName)
    }
}
