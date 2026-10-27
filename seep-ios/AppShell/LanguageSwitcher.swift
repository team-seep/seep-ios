import Foundation
import WidgetKit

/// 설정 "언어"에서 쓰는 앱 언어 바꾸기 (GH-103 R-21~R-23)
protocol LanguageSwitching {
    /// 사용자가 고른 언어. nil 이면 기기 언어
    var selectedCode: String? { get }
    var availableCodes: [String] { get }
    func select(_ code: String?)
}

struct LanguageSwitcher: LanguageSwitching {
    static let appleLanguagesKey = "AppleLanguages"

    var language: AppLanguage = .shared
    var standardDefaults: UserDefaults = .standard

    var selectedCode: String? { language.selectedCode }
    var availableCodes: [String] { language.availableCodes }

    func select(_ code: String?) {
        // iOS 가 읽는 앱 언어도 맞춘다. 권한 안내 같은 시스템 문구가 다음 실행부터 같은 언어로 나오고, iOS 설정의 앱 언어와도 같아진다.
        // "기기 언어 따르기"는 이 값을 지운 뒤의 기기 언어를 읽으므로 먼저 바꾼다
        if let code {
            standardDefaults.set([code], forKey: Self.appleLanguagesKey)
        } else {
            standardDefaults.removeObject(forKey: Self.appleLanguagesKey)
        }
        language.select(code)
        // 예약해 둔 D-day 알림과 위젯도 새 언어로 다시 만든다 (R-22)
        NotificationLanguageRefresh().run()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 앱을 켤 때. 앱 안에서 고른 뒤 iOS 설정에서 앱 언어를 다시 바꿨으면 iOS 쪽을 따른다 (R-23)
    static func syncWithSystem(
        language: AppLanguage = .shared,
        systemCode: String? = Bundle.main.preferredLocalizations.first
    ) {
        guard let selected = language.selectedCode, let systemCode, systemCode != selected,
              language.availableCodes.contains(systemCode) else { return }
        language.select(systemCode)
    }
}
