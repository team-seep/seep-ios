import Foundation
import Combine

extension AppLockViewModel {
    struct Input {
        /// 스플래시가 끝나고 홈이 뜰 때 (콜드 스타트, R-5 ①)
        let didShowMain = PassthroughSubject<Void, Never>()
        let willResignActive = PassthroughSubject<Void, Never>()
        let didEnterBackground = PassthroughSubject<Void, Never>()
        let willEnterForeground = PassthroughSubject<Void, Never>()
        let didBecomeActive = PassthroughSubject<Void, Never>()
        let didTapUnlock = PassthroughSubject<Void, Never>()
    }

    enum LockState: Equatable {
        case unlocked
        /// 앱 전환기 스냅샷용 덮개. 버튼 없이 가리기만 한다 (R-7)
        case covered
        /// 인증해야 열리는 잠금 화면 (R-6)
        case locked
    }

    struct Output {
        let screenName: ScreenName = .appLock
        let lockState = CurrentValueSubject<LockState, Never>(.unlocked)
        let description = CurrentValueSubject<String, Never>("")
        let unlockButtonTitle = CurrentValueSubject<String, Never>("")
    }

    struct State {
        /// 스플래시 전에는 생명주기 이벤트로 잠그지 않는다. 콜드 스타트는 홈이 뜰 때 잠근다
        var hasShownMain = false
        var isActive = false
        /// 잠길 때 한 번만 자동으로 인증을 요청한다. 인증 창이 닫히며 다시 활성화돼도 또 묻지 않는다 (R-6)
        var needsAutoAuthentication = false
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

/// 앱 전체를 덮는 잠금 화면과 그 생명주기 판정 (GH-46 R-5 ~ R-7)
final class AppLockViewModel {
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
        input.didShowMain
            .withUnretained(self)
            .sink { (owner: AppLockViewModel, _) in
                owner.state.hasShownMain = true
                // 콜드 스타트는 지난 백그라운드 시각과 상관없이 잠근다
                guard owner.isLockAvailable else { return }
                owner.lock()
            }
            .store(in: &cancellables)

        input.willResignActive
            .withUnretained(self)
            .sink { (owner: AppLockViewModel, _) in
                owner.state.isActive = false
                owner.coverIfNeeded()
            }
            .store(in: &cancellables)

        input.didEnterBackground
            .withUnretained(self)
            .sink { (owner: AppLockViewModel, _) in
                owner.dependency.preference.appLockBackgroundAt = owner.dependency.now()
                owner.coverIfNeeded()
            }
            .store(in: &cancellables)

        input.willEnterForeground
            .withUnretained(self)
            .sink { (owner: AppLockViewModel, _) in
                owner.lockIfNeeded()
            }
            .store(in: &cancellables)

        input.didBecomeActive
            .withUnretained(self)
            .sink { (owner: AppLockViewModel, _) in
                owner.state.isActive = true
                owner.handleDidBecomeActive()
            }
            .store(in: &cancellables)

        input.didTapUnlock
            .withUnretained(self)
            .sink { (owner: AppLockViewModel, _) in
                owner.authenticate()
            }
            .store(in: &cancellables)
    }

    /// 잠금을 켰고 인증할 수 있을 때만 잠근다. 기기 암호를 지워 인증이 불가능하면 영영 못 열게 되므로 잠그지 않는다 (R-11)
    private var isLockAvailable: Bool {
        return dependency.preference.isAppLockEnabled && dependency.authenticationManager.canAuthenticate()
    }

    private func coverIfNeeded() {
        guard state.hasShownMain,
              dependency.preference.isAppLockEnabled,
              output.lockState.value == .unlocked,
              // 잠금 끄기 등 앱이 띄운 인증 창 때문에 비활성화될 때는 덮지 않는다 (R-7)
              !dependency.authenticationManager.isAuthenticating else { return }

        updateTexts()
        output.lockState.send(.covered)
    }

    private func lockIfNeeded() {
        guard state.hasShownMain, isLockAvailable else { return }

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
        state.needsAutoAuthentication = true
        output.lockState.send(.locked)
        // 콜드 스타트처럼 이미 활성 상태면 바로 묻는다. 아니면 활성화될 때 묻는다
        if state.isActive {
            authenticateAutomaticallyIfNeeded()
        }
    }

    private func handleDidBecomeActive() {
        switch output.lockState.value {
        case .covered:
            // 60초 안에 돌아왔다 (R-7)
            output.lockState.send(.unlocked)
        case .locked:
            authenticateAutomaticallyIfNeeded()
        case .unlocked:
            break
        }
    }

    private func authenticateAutomaticallyIfNeeded() {
        guard state.needsAutoAuthentication else { return }
        state.needsAutoAuthentication = false
        authenticate()
    }

    private func authenticate() {
        guard output.lockState.value == .locked,
              !dependency.authenticationManager.isAuthenticating else { return }

        dependency.authenticationManager.authenticate(reason: Strings.AppLock.reason) { [weak self] isSuccess in
            guard let self, isSuccess else { return }
            sendClickLog(objectId: .unlockApp)
            output.lockState.send(.unlocked)
        }
    }

    private func updateTexts() {
        let biometryName = dependency.authenticationManager.biometry().name
        output.description.send(Strings.AppLock.Screen.descriptionFormat(biometryName))
        output.unlockButtonTitle.send(Strings.AppLock.Screen.unlockButtonFormat(biometryName))
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
