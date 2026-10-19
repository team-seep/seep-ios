import Foundation
import Combine

extension AppLockBottomSheetViewModel {
    struct Input {
        let didTapConfirm = PassthroughSubject<Void, Never>()
        let didTapClose = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let screenName: ScreenName = .appLockBottomSheet
        /// 시트를 연 시점의 잠금 여부. 켜져 있으면 "잠금 끄기" 시트다 (R-2)
        let isEnabled: Bool
        let title: String
        let titleBold: String
        let description: String
        let confirmButtonTitle: String
        let closeButtonTitle: String
        /// 인증에 성공해 잠금을 바꿨을 때. 홈 자물쇠 아이콘을 바꾼다 (R-3)
        let didChangeAppLock = PassthroughSubject<Bool, Never>()
        let toast = PassthroughSubject<String, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case dismiss
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

/// 홈 자물쇠 버튼으로 여는 잠금 켜기·끄기 바텀시트 (GH-46 R-2 ~ R-4)
final class AppLockBottomSheetViewModel {
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        self.output = Self.makeOutput(
            isEnabled: dependency.preference.isAppLockEnabled,
            biometry: dependency.authenticationManager.biometry()
        )
        bind()
    }

    private static func makeOutput(isEnabled: Bool, biometry: AppLockBiometry) -> Output {
        if isEnabled {
            return Output(
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
        return Output(
            isEnabled: false,
            title: Strings.AppLock.Sheet.enableTitle,
            titleBold: Strings.AppLock.Sheet.enableTitleBold,
            description: description,
            confirmButtonTitle: Strings.AppLock.Sheet.enableButtonFormat(biometry.name),
            closeButtonTitle: Strings.AppLock.Sheet.later
        )
    }

    private func bind() {
        input.didTapConfirm
            .withUnretained(self)
            .sink { (owner: AppLockBottomSheetViewModel, _) in
                if owner.output.isEnabled {
                    owner.disableAppLock()
                } else {
                    owner.enableAppLock()
                }
            }
            .store(in: &cancellables)

        input.didTapClose
            .withUnretained(self)
            .sink { (owner: AppLockBottomSheetViewModel, _) in
                owner.output.route.send(.dismiss)
            }
            .store(in: &cancellables)
    }

    private func enableAppLock() {
        guard dependency.authenticationManager.canAuthenticate() else {
            output.toast.send(Strings.AppLock.Toast.noPasscode)
            return
        }

        dependency.authenticationManager.authenticate(reason: Strings.AppLock.reason) { [weak self] isSuccess in
            guard let self, isSuccess else { return }
            updateAppLock(isEnabled: true)
        }
    }

    private func disableAppLock() {
        // 기기 암호를 지워 인증할 수 없으면 묻지 않고 끈다. 끌 수 없으면 잠금만 남은 채 쓸모가 없다 (R-11)
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
        sendClickLog(objectId: isEnabled ? .enableAppLock : .disableAppLock)
        output.didChangeAppLock.send(isEnabled)
        output.route.send(.dismiss)
    }

    private func sendClickLog(objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId
        ))
    }
}
