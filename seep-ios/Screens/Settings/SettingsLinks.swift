import Foundation

/// 설정 탭이 여는 바깥 링크 (GH-64 R-25, R-28)
enum SettingsLinks {
    /// App Store 앱 id ("싶 - 나를 위한 위시리스트"). 비어 있으면 설정에서 "앱 평가하기" 줄을 숨긴다 (GH-77 R-1, R-4)
    static let appStoreID: String? = "1559479928"
    /// 문의 받는 메일 주소. 비어 있으면 "문의하기" 줄을 숨긴다 (GH-77 R-2, R-4)
    static let contactEmail: String? = "dbgustlr92@gmail.com"

    /// 앱의 시스템 설정 화면. UIKit `UIApplication.openSettingsURLString`과 같은 값
    static let appSettingsURL = URL(string: "app-settings:")

    static func reviewURL(appStoreID: String?) -> URL? {
        guard let appStoreID, !appStoreID.isEmpty else { return nil }
        return URL(string: "itms-apps://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    /// 제목 "[싶 문의]", 본문에 앱 버전·iOS 버전·기기 모델을 미리 채운 `mailto:` (TC-302)
    static func contactMailURL(email: String?, appVersion: String, osVersion: String, deviceModel: String) -> URL? {
        guard let email, !email.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: Strings.Settings.Contact.subject),
            URLQueryItem(name: "body", value: Strings.Settings.Contact.bodyFormat(appVersion, osVersion, deviceModel))
        ]
        return components.url
    }
}

/// 문의 메일 본문·버전 줄에 쓰는 기기 정보. UIKit(`UIDevice`) 없이 읽는다
struct DeviceInfo: Equatable {
    let appVersion: String
    let osVersion: String
    let deviceModel: String

    static var current: DeviceInfo {
        DeviceInfo(
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            osVersion: osVersionText(ProcessInfo.processInfo.operatingSystemVersion),
            deviceModel: machineIdentifier()
        )
    }

    /// 18.1.0 → "18.1", 18.1.2 → "18.1.2"
    static func osVersionText(_ version: OperatingSystemVersion) -> String {
        let base = "\(version.majorVersion).\(version.minorVersion)"
        return version.patchVersion > 0 ? base + ".\(version.patchVersion)" : base
    }

    /// "iPhone17,1". 시뮬레이터는 실제 기기 대신 시뮬레이터가 흉내 내는 모델을 돌려준다
    private static func machineIdentifier() -> String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
