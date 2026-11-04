import XCTest

@testable import seep_ios

/// 앱 안에서 언어 바꾸기 (GH-103 R-21~R-23)
final class InAppLanguageTests: ViewModelTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test-gh103-language-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        // 공용 인스턴스로 바꾼 언어는 다음 테스트에 남지 않게 되돌린다
        AppLanguage.shared.select(nil)
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeLanguage(base: Locale = Locale(identifier: "ko_KR"), device: [String] = ["ko-KR"]) -> AppLanguage {
        AppLanguage(defaults: defaults, resourceBundle: Bundle(for: AppLanguage.self), baseLocale: { base }, preferredLanguages: { device })
    }

    private func lproj(_ code: String) -> String? {
        Bundle(for: AppLanguage.self).path(forResource: code, ofType: "lproj")
    }

    private func makeSettings(_ language: MockLanguageSwitcher) -> SettingsViewModel {
        SettingsViewModel(dependency: .init(
            preference: Preference(name: "test-gh103-language-settings"),
            authenticationManager: MockAuthenticationManager(),
            notificationManager: MockNotificationManager(),
            logManager: logManager,
            language: language
        ))
    }

    // MARK: GH-103 TC17

    func test_GH103_TC17_언어목록에서_일본어를고르면_저장되고_줄과로그에반영된다() {
        // Given
        let language = MockLanguageSwitcher(selectedCode: nil)
        let sut = makeSettings(language)
        XCTAssertTrue(sut.state.groups.flatMap(\.rows).contains(.language(Strings.Settings.Language.system)))

        // When
        sut.send(.selectLanguage("ja"))

        // Then
        XCTAssertEqual(language.selectedCodes, ["ja"])
        XCTAssertEqual(sut.state.languageCode, "ja")
        XCTAssertTrue(sut.state.groups.flatMap(\.rows).contains(.language("日本語")))
        let events = clickEvents(objectId: .selectLanguage)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, "ja")
    }

    func test_GH103_TC17_지금과같은언어를다시고르면_다시만들지않는다() {
        // Given
        let language = MockLanguageSwitcher(selectedCode: "en")
        let sut = makeSettings(language)

        // When
        sut.send(.selectLanguage("en"))

        // Then
        XCTAssertTrue(language.selectedCodes.isEmpty)
    }

    // MARK: GH-103 TC18

    func test_GH103_TC18_영어를고르면_기기언어와상관없이_문구·날짜·금액이영어로나온다() {
        // Given: 한국어 기기
        let date = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 10, day: 28, hour: 12).date ?? Date()

        // When
        AppLanguage.shared.select("en")

        // Then
        XCTAssertEqual(Strings.Settings.Language.title, "Language")
        XCTAssertEqual(AppLanguage.shared.locale.language.languageCode, .english)
        XCTAssertEqual(DisplayDate.monthDay(date, calendar: Calendar(identifier: .gregorian)), "Oct 28")
        XCTAssertFalse(AmountFormatter.money(769_000, currency: "KRW").hasSuffix("원"))
    }

    func test_GH103_TC18_언어만바꾸고_지역은기기것을쓴다() {
        // Given: 한국 지역 기기에서
        let sut = makeLanguage()

        // When
        sut.select("en")

        // Then: 영어 + 한국 지역이라 새 위시 기본 통화는 그대로 원화
        XCTAssertEqual(sut.code, "en")
        XCTAssertEqual(sut.locale.region, .southKorea)
        XCTAssertEqual(AmountFormatter.defaultCurrency(locale: sut.locale), "KRW")
        XCTAssertEqual(sut.bundle.bundlePath, lproj("en"))
    }

    // MARK: GH-103 TC19

    func test_GH103_TC19_기기언어따르기를고르면_저장값이지워지고_앱을다시켜지않아도기기언어로돌아간다() {
        // Given: 한국어 기기에서 日本語 를 고른 상태
        let sut = makeLanguage()
        sut.select("ja")
        XCTAssertEqual(sut.bundle.bundlePath, lproj("ja"))

        // When
        sut.select(nil)

        // Then
        XCTAssertNil(sut.selectedCode)
        XCTAssertNil(defaults.string(forKey: AppLanguage.storageKey))
        XCTAssertEqual(sut.code, "ko")
        XCTAssertEqual(sut.bundle.bundlePath, lproj("ko"))
        XCTAssertEqual(sut.locale.language.languageCode, .korean)
    }

    func test_GH103_TC19_기기언어가번역없는언어면_원문한국어다() {
        // Given / When: 프랑스어 기기
        let sut = makeLanguage(base: Locale(identifier: "fr_FR"), device: ["fr-FR"])

        // Then
        XCTAssertEqual(sut.code, "ko")
    }

    func test_GH103_TC19_번역이없는언어가저장돼있으면_무시한다() {
        // Given
        defaults.set("fr", forKey: AppLanguage.storageKey)

        // When
        let sut = makeLanguage()

        // Then
        XCTAssertNil(sut.selectedCode)
        XCTAssertEqual(sut.bundle.bundlePath, lproj("ko"))
    }

    // MARK: GH-103 TC20

    func test_GH103_TC20_iOS설정에서앱언어를바꿨으면_켤때그언어를따른다() {
        // Given: 앱 안에서 English 를 골랐는데
        let sut = makeLanguage()
        sut.select("en")

        // When: iOS 설정에서 日本語 로 바꾸고 앱을 켜면
        LanguageSwitcher.syncWithSystem(language: sut, systemCode: "ja")

        // Then
        XCTAssertEqual(sut.selectedCode, "ja")
    }

    func test_GH103_TC20_기기언어를따르는중이면_켤때아무것도바꾸지않는다() {
        // Given
        let sut = makeLanguage()

        // When
        LanguageSwitcher.syncWithSystem(language: sut, systemCode: "en")

        // Then
        XCTAssertNil(sut.selectedCode)
    }
}

final class MockLanguageSwitcher: LanguageSwitching {
    private(set) var selectedCode: String?
    var availableCodes = ["ko", "en", "ja", "zh-Hans", "zh-Hant"]
    private(set) var selectedCodes: [String?] = []

    init(selectedCode: String?) {
        self.selectedCode = selectedCode
    }

    func select(_ code: String?) {
        selectedCodes.append(code)
        selectedCode = code
    }
}
