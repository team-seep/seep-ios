import Foundation
import Observation

extension SettingsViewModel {
    enum Action: Equatable {
        /// 탭이 보일 때·앱이 다시 활성화될 때. 설정 앱에서 바꾼 알림 권한·잠금 상태를 다시 읽는다 (R-25)
        case onAppear
        case tapAppLock
        /// 잠금 시트가 닫혔을 때. 인증에 실패·취소했으면 스위치가 원래대로 돌아간다
        case appLockSheetDismissed
        case tapNotification
        case tapViewType
        case selectViewType(ViewType)
        /// 시작 카테고리 (GH-86 R-1). nil 이면 마지막으로 본 카테고리
        case tapStartCategory
        case selectStartCategory(Category?)
        case tapWidgetGuide
        case tapControlGuide
        case tapRateApp
        case tapContact
        /// 메일 앱을 열지 못했을 때 (R-28)
        case contactUnavailable
        case tapLicense
        case routeHandled
    }

    struct State: Equatable {
        var groups: [SettingsGroup] = []
        var isAppLockEnabled = false
        var notificationStatus: NotificationAuthorization?
        var viewType: ViewType = .list
        var startCategory: Category?
    }

    enum Route: Equatable {
        case appLockSheet
        case viewTypeDialog
        case startCategoryDialog
        case openURL(URL)
        case push(AppDestination)
        case toast(String)
    }

    struct Dependency {
        let preference: Preference
        let authenticationManager: AuthenticationManagerProtocol
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        let deviceInfo: DeviceInfo
        let appStoreID: String?
        let contactEmail: String?
        let pasteboard: PasteboardWriting

        init(
            preference: Preference = .shared,
            authenticationManager: AuthenticationManagerProtocol = AuthenticationManager.shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            deviceInfo: DeviceInfo = .current,
            appStoreID: String? = SettingsLinks.appStoreID,
            contactEmail: String? = SettingsLinks.contactEmail,
            pasteboard: PasteboardWriting = SystemPasteboard()
        ) {
            self.preference = preference
            self.authenticationManager = authenticationManager
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.deviceInfo = deviceInfo
            self.appStoreID = appStoreID
            self.contactEmail = contactEmail
            self.pasteboard = pasteboard
        }
    }
}

/// 설정 탭 (GH-64 R-24 ~ R-29)
@Observable
final class SettingsViewModel {
    let screenName: ScreenName = .settings
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency
    private var statusTask: Task<Void, Never>?

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        reloadLocalState()
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            reloadLocalState()
            reloadNotificationStatus()

        case .tapAppLock:
            sendClickLog(objectId: .appLock, extraParameters: [.enabled: state.isAppLockEnabled])
            route = .appLockSheet

        case .appLockSheetDismissed:
            reloadLocalState()

        case .tapNotification:
            sendClickLog(objectId: .notificationSetting)
            if let url = SettingsLinks.appSettingsURL {
                route = .openURL(url)
            }

        case .tapViewType:
            sendClickLog(objectId: .viewTypeSetting)
            route = .viewTypeDialog

        case .selectViewType(let viewType):
            dependency.preference.viewType = viewType
            reloadLocalState()

        case .tapStartCategory:
            route = .startCategoryDialog

        case .selectStartCategory(let category):
            sendClickLog(objectId: .selectStartCategory, extraParameters: [.type: category?.rawValue ?? "last"])
            dependency.preference.startCategory = category
            reloadLocalState()

        case .tapWidgetGuide:
            sendClickLog(objectId: .widgetGuide)
            route = .push(.widgetGuide)

        case .tapControlGuide:
            sendClickLog(objectId: .controlGuide)
            route = .push(.controlGuide)

        case .tapRateApp:
            sendClickLog(objectId: .rateApp)
            if let url = SettingsLinks.reviewURL(appStoreID: dependency.appStoreID) {
                route = .openURL(url)
            }

        case .tapContact:
            sendClickLog(objectId: .contact)
            let info = dependency.deviceInfo
            if let url = SettingsLinks.contactMailURL(
                email: dependency.contactEmail,
                appVersion: info.appVersion,
                osVersion: info.osVersion,
                deviceModel: info.deviceModel
            ) {
                route = .openURL(url)
            }

        case .contactUnavailable:
            // 메일 계정이 없으면 주소를 복사해 다른 메일 앱에 붙여넣게 한다 (#64 R-28, GH-77 R-3)
            guard let email = dependency.contactEmail else { return }
            dependency.pasteboard.copy(email)
            route = .toast(Strings.Settings.Contact.copiedFormat(email))

        case .tapLicense:
            sendClickLog(objectId: .license)
            route = .push(.license)

        case .routeHandled:
            route = nil
        }
    }

    private func reloadLocalState() {
        state.isAppLockEnabled = dependency.preference.isAppLockEnabled
        state.viewType = dependency.preference.viewType
        state.startCategory = dependency.preference.startCategory
        rebuildGroups()
    }

    private func reloadNotificationStatus() {
        statusTask?.cancel()
        let notificationManager = dependency.notificationManager
        statusTask = Task { @MainActor [weak self] in
            let status = await notificationManager.authorizationStatus()
            guard let self, !Task.isCancelled else { return }
            state.notificationStatus = status
            rebuildGroups()
        }
    }

    private func rebuildGroups() {
        state.groups = SettingsMenuBuilder.groups(
            biometry: dependency.authenticationManager.biometry(),
            isAppLockEnabled: state.isAppLockEnabled,
            notificationStatus: state.notificationStatus,
            viewType: state.viewType,
            startCategory: state.startCategory,
            version: dependency.deviceInfo.appVersion,
            isRateAppAvailable: SettingsLinks.reviewURL(appStoreID: dependency.appStoreID) != nil,
            isContactAvailable: !(dependency.contactEmail ?? "").isEmpty
        )
    }

    private func sendClickLog(objectId: LogObjectId, extraParameters: [ParameterName: Any]? = nil) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: objectId,
            extraParameters: extraParameters
        ))
    }
}
