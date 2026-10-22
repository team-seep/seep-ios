import Foundation
import Observation

extension AppLockSheetViewModel {
    enum Action: Equatable {
        case tapConfirm
        case tapClose
        case routeHandled
    }

    struct State: Equatable {
        /// 시트를 연 시점의 잠금 여부. 켜져 있으면 "잠금 끄기" 시트다 (GH-46 R-2)
        let isEnabled: Bool
        let title: String
        let titleBold: String
        let description: String
        let confirmButtonTitle: String
        let closeButtonTitle: String
    }

    enum Route: Equatable {
        /// 인증에 성공해 잠금을 바꿨으면 바뀐 값, 그냥 닫았으면 nil
        case dismiss(changedTo: Bool?)
        case toast(String)
    }

    struct Dependency {
        let preference: Preference
        let authenticationManager: AuthenticationManagerProtocol
        let logManager: LogManagerProtocol

        init(
            preference: Preference = .shared,
            authenticationManager: AuthenticationManagerProtocol = AuthenticationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.preference = preference
            self.authenticationManager = authenticationManager
            self.logManager = logManager
        }
    }
}

/// 설정 탭 잠금 줄로 여는 잠금 켜기·끄기 시트 (GH-46 R-2 ~ R-4, R-11 / GH-64 R-25, TC-1101)
@Observable
final class AppLockSheetViewModel {
    let screenName: ScreenName = .appLockBottomSheet
    let state: State
    private(set) var route: Route?

    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        self.state = Self.makeState(
            isEnabled: dependency.preference.isAppLockEnabled,
            biometry: dependency.authenticationManager.biometry()
        )
    }

    func send(_ action: Action) {
        switch action {
        case .tapConfirm:
            // 인증 창이 뜨기 전 버튼을 한 번 더 눌러도 인증을 겹쳐 요청하지 않는다
            guard !dependency.authenticationManager.isAuthenticating else { return }
            if state.isEnabled {
                disableAppLock()
            } else {
                enableAppLock()
            }

        case .tapClose:
            route = .dismiss(changedTo: nil)

        case .routeHandled:
            route = nil
        }
    }

    private static func makeState(isEnabled: Bool, biometry: AppLockBiometry) -> State {
        if isEnabled {
            return State(
                isEnabled: true,
                title: Strings.AppLock.Sheet.disableTitle,
                titleBold: Strings.AppLock.Sheet.disableTitleBold,
                description: Strings.AppLock.Sheet.disableDescription,
                confirmButtonTitle: Strings.AppLock.Sheet.disableButton,
                closeButtonTitle: Strings.AppLock.Sheet.close
            )
        }

        let description = biometry == .passcode
            ? Strings.AppLock.Sheet.enableDescriptionPasscode
            : Strings.AppLock.Sheet.enableDescriptionFormat(biometry.name)
        return State(
            isEnabled: false,
            title: Strings.AppLock.Sheet.enableTitle,
            titleBold: Strings.AppLock.Sheet.enableTitleBold,
            description: description,
            confirmButtonTitle: Strings.AppLock.Sheet.enableButtonFormat(biometry.name),
            closeButtonTitle: Strings.AppLock.Sheet.later
        )
    }

    private func enableAppLock() {
        guard dependency.authenticationManager.canAuthenticate() else {
            route = .toast(Strings.AppLock.Toast.noPasscode)
            return
        }

        dependency.authenticationManager.authenticate(reason: Strings.AppLock.reason) { [weak self] isSuccess in
            guard let self, isSuccess else { return }
            updateAppLock(isEnabled: true)
        }
    }

    private func disableAppLock() {
        // 기기 암호를 지워 인증할 수 없으면 묻지 않고 끈다. 끌 수 없으면 잠금만 남은 채 쓸모가 없다 (GH-46 R-11)
        guard dependency.authenticationManager.canAuthenticate() else {
            updateAppLock(isEnabled: false)
            return
        }

        dependency.authenticationManager.authenticate(reason: Strings.AppLock.reason) { [weak self] isSuccess in
            guard let self, isSuccess else { return }
            updateAppLock(isEnabled: false)
        }
    }

    private func updateAppLock(isEnabled: Bool) {
        dependency.preference.isAppLockEnabled = isEnabled
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: isEnabled ? .enableAppLock : .disableAppLock
        ))
        route = .dismiss(changedTo: isEnabled)
    }
}
