import Foundation

/// 앱 안에서 고른 언어 (GH-103 R-21). 기기 언어와 따로 앱·위젯 문구, 날짜·금액 표기를 바꾼다.
/// 고른 값은 App Group 에 두어 위젯도 같은 언어로 그린다. 고르지 않았으면(nil) 기기 언어를 따른다
final class AppLanguage: @unchecked Sendable {
    static let shared = AppLanguage()
    static let storageKey = "appLanguage"
    /// 설정에 보일 순서. 번들에 번역이 있는 언어만 나온다
    static let displayOrder = ["ko", "en", "ja", "zh-Hans", "zh-Hant"]

    private struct Resolved {
        let stored: String?
        let code: String
        let bundle: Bundle
        let locale: Locale
    }

    private let defaults: UserDefaults?
    private let resourceBundle: Bundle
    private let baseLocale: () -> Locale
    private let preferredLanguages: () -> [String]
    private let lock = NSLock()
    private var resolved: Resolved?

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: AppDatabase.appGroupIdentifier),
        resourceBundle: Bundle = Bundle(for: AppLanguage.self),
        baseLocale: @escaping () -> Locale = { Locale.current },
        // Bundle.main·Locale.current 는 켤 때의 언어로 굳어 있어, 기기 언어로 돌아갈 때는 설정값을 직접 읽는다
        preferredLanguages: @escaping () -> [String] = {
            UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? Locale.preferredLanguages
        }
    ) {
        self.defaults = defaults
        self.resourceBundle = resourceBundle
        self.baseLocale = baseLocale
        self.preferredLanguages = preferredLanguages
    }

    /// 사용자가 고른 언어. nil 이면 기기 언어
    var selectedCode: String? {
        guard let code = defaults?.string(forKey: Self.storageKey), availableCodes.contains(code) else { return nil }
        return code
    }

    /// 지금 보여 주는 언어. 번역이 없는 기기 언어면 원문(ko)
    var code: String { current().code }

    var availableCodes: [String] {
        Self.displayOrder.filter(resourceBundle.localizations.contains)
    }

    /// 문구를 읽을 번들. 고른 언어(없으면 기기 언어)의 폴더(.lproj)
    var bundle: Bundle { current().bundle }

    /// 날짜·금액 표기. 언어만 바꾸고 지역(통화·주 시작)은 기기 것을 그대로 쓴다
    var locale: Locale { current().locale }

    /// 언어를 고른다. 앱 안에서만 부른다(위젯은 읽기만)
    func select(_ code: String?) {
        lock.lock()
        defer { lock.unlock() }
        if let code {
            defaults?.set(code, forKey: Self.storageKey)
        } else {
            defaults?.removeObject(forKey: Self.storageKey)
        }
        resolved = nil
    }

    /// 그 언어를 그 언어로 쓴 이름("English", "日本語")
    static func displayName(of code: String) -> String {
        let name = Locale(identifier: code).localizedString(forIdentifier: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    private func current() -> Resolved {
        lock.lock()
        defer { lock.unlock() }
        // 위젯과 앱이 같은 값을 쓰므로 매번 저장값을 보고, 바뀌었을 때만 다시 만든다
        let stored = defaults?.string(forKey: Self.storageKey)
        if let resolved, resolved.stored == stored {
            return resolved
        }
        let available = availableCodes
        let code = stored.flatMap { available.contains($0) ? $0 : nil } ?? deviceCode(available: available)
        let bundle = resourceBundle.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? resourceBundle
        let next = Resolved(stored: stored, code: code, bundle: bundle, locale: makeLocale(language: code))
        resolved = next
        return next
    }

    /// 기기 언어 순서대로 번역이 있는 첫 언어. 하나도 없으면 원문(ko)이다 (GH-100: iOS 는 이때 영어를 고른다)
    private func deviceCode(available: [String]) -> String {
        for preference in preferredLanguages() {
            // zh-HK → zh-Hant 처럼 지역·문자 짝은 iOS 가 맞춘다. 언어가 다르면 고른 것이 아니라 대신 넣은 것이다
            guard let match = Bundle.preferredLocalizations(from: available, forPreferences: [preference]).first,
                  Locale.Language(identifier: match).languageCode == Locale.Language(identifier: preference).languageCode
            else { continue }
            return match
        }
        return "ko"
    }

    private func makeLocale(language: String) -> Locale {
        var components = Locale.Components(locale: baseLocale())
        var languageComponents = Locale.Language.Components(identifier: language)
        // 지역은 언어 쪽에 들어 있어, 언어만 바꾸면 지워진다
        languageComponents.region = components.languageComponents.region ?? components.region
        components.languageComponents = languageComponents
        return Locale(components: components)
    }
}
