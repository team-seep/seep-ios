import Foundation

/// 설정 줄 하나
enum SettingsRow: Equatable, Identifiable {
    case appLock(title: String, description: String, isOn: Bool)
    case notification(status: NotificationAuthorization?)
    case viewType(ViewType)
    case widgetGuide
    case controlGuide
    case rateApp
    case contact
    case license
    case version(String)

    var id: String {
        switch self {
        case .appLock: return "app_lock"
        case .notification: return "notification"
        case .viewType: return "view_type"
        case .widgetGuide: return "widget_guide"
        case .controlGuide: return "control_guide"
        case .rateApp: return "rate_app"
        case .contact: return "contact"
        case .license: return "license"
        case .version: return "version"
        }
    }
}

struct SettingsGroup: Equatable, Identifiable {
    let title: String
    let rows: [SettingsRow]

    var id: String { title }
}

/// 설정 탭 줄 목록 (GH-64 R-24 ~ R-28, TC-17). 생체 인증 종류에 따라 잠금 줄 이름이 바뀐다
enum SettingsMenuBuilder {
    static func groups(
        biometry: AppLockBiometry,
        isAppLockEnabled: Bool,
        notificationStatus: NotificationAuthorization?,
        viewType: ViewType,
        version: String
    ) -> [SettingsGroup] {
        [
            SettingsGroup(title: Strings.Settings.Group.lockNotification, rows: [
                .appLock(
                    title: lockTitle(biometry: biometry),
                    description: lockDescription(biometry: biometry),
                    isOn: isAppLockEnabled
                ),
                .notification(status: notificationStatus)
            ]),
            SettingsGroup(title: Strings.Settings.Group.view, rows: [
                .viewType(viewType)
            ]),
            SettingsGroup(title: Strings.Settings.Group.quickWrite, rows: [
                .widgetGuide,
                .controlGuide
            ]),
            SettingsGroup(title: Strings.Settings.Group.info, rows: [
                .rateApp,
                .contact,
                .license,
                .version(version)
            ])
        ]
    }

    /// "Face ID로 잠그기" / "Touch ID로 잠그기" / "암호로 잠그기" (R-25)
    static func lockTitle(biometry: AppLockBiometry) -> String {
        switch biometry {
        case .faceID, .touchID:
            return Strings.Settings.Lock.titleFormat(biometry.name)
        case .passcode:
            return Strings.Settings.Lock.titlePasscode
        }
    }

    static func lockDescription(biometry: AppLockBiometry) -> String {
        switch biometry {
        case .faceID, .touchID:
            return Strings.Settings.Lock.descriptionFormat(biometry.name)
        case .passcode:
            return Strings.Settings.Lock.descriptionPasscode
        }
    }
}
