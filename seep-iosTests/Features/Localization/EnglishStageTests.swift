import XCTest

@testable import seep_ios_dev

/// 다국어 2단계 — 영어 번역·설정 언어 줄·위시별 통화 (GH-103)
final class EnglishStageTests: WishFormFeatureTestCase {
    private let korean = Locale(identifier: "ko_KR")
    private let english = Locale(identifier: "en_US")

    /// 앱 번들의 영어 문구 (기기 언어와 상관없이 en.lproj 를 직접 읽는다)
    private func english(_ key: String, table: String = "Localization") throws -> String {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let bundle = try XCTUnwrap(Bundle(path: path))
        return bundle.localizedString(forKey: key, value: "⚠️없음", table: table)
    }

    // MARK: GH-103 TC2·TC3

    func test_GH103_TC2_TC3_위젯·컨트롤·권한문구가_영어로들어있다() throws {
        // Given / When / Then: 원문과 다른 영어 값이 있다
        XCTAssertEqual(try english("category_want_to_do"), "Do")
        XCTAssertEqual(try english("category_want_to_get"), "Get")
        XCTAssertEqual(try english("category_want_to_go"), "Go")
        XCTAssertFalse(try english("widget.lock_screen.nearest").contains("싶"))
        XCTAssertFalse(try english("빠르게 등록하기", table: "Localizable").contains("빠르게"))
        XCTAssertFalse(try english("NSPhotoLibraryUsageDescription", table: "InfoPlist").contains("앨범"))
    }

    // MARK: GH-103 TC4

    func test_GH103_TC4_개수문구는_1이면단수_2이상이면복수다() throws {
        // Given: 일수를 넣는 편지 제목 (영어 one/other)
        let format = try english("home.finish_note.letter_title_format")

        // When
        let one = String(format: format, locale: english, 1)
        let three = String(format: format, locale: english, 3)

        // Then
        XCTAssertEqual(one, "You from 1 day ago\nsent you a letter")
        XCTAssertEqual(three, "You from 3 days ago\nsent you a letter")
    }

    // MARK: GH-103 TC6

    func test_GH103_TC6_굵게칠할부분이_영어긴문장안에있다() throws {
        // Given / When / Then
        for key in ["home.title_format.want_to_do", "home.title_format.want_to_get", "home.title_format.want_to_go"] {
            let sentence = String(format: try english(key), locale: english, 3)
            XCTAssertTrue(sentence.contains(try english("home.title_format.bold")), key)
        }
        for key in ["home.empty_title.want_to_do", "home.empty_title.want_to_get", "home.empty_title.want_to_go"] {
            XCTAssertTrue(try english(key).contains(try english("home.empty_title.bold")), key)
        }
    }

    // MARK: GH-103 TC7·TC8

    func test_GH103_TC7_TC8_설정언어줄은_고른언어를보여주고_누르면언어목록을띄운다() {
        // Given: 앱 안에서 English 를 고른 상태
        let sut = SettingsViewModel(dependency: .init(
            preference: Preference(name: "test-gh103-settings"),
            authenticationManager: MockAuthenticationManager(),
            notificationManager: notificationManager,
            logManager: logManager,
            language: MockLanguageSwitcher(selectedCode: "en")
        ))

        // When
        sut.send(.tapLanguage)

        // Then
        XCTAssertTrue(sut.state.groups.flatMap(\.rows).contains(.language("English")))
        XCTAssertEqual(sut.route, .languageDialog)
        XCTAssertEqual(clickEvents(objectId: .language).count, 1)
    }

    // MARK: GH-103 TC11

    func test_GH103_TC11_v5DB를v6로올리면_기존위시통화는KRW이고금액은그대로다() throws {
        // Given: v5 스키마에 목표 금액 769,000원 위시
        let database = try AppDatabase.makeInMemory(migratedUpTo: "v5", seedSQL: [
            "INSERT INTO wish (id, category, title, targetAmount, createdAt, updatedAt) VALUES ('W', 'category_want_to_get', '맥북', 769000, 100, 0)"
        ])

        // When
        let wish = WishRepositoryImpl(database: database).fetchWish(id: "W")

        // Then
        XCTAssertEqual(wish?.currency, "KRW")
        XCTAssertEqual(wish?.targetAmount, 769_000)
    }

    // MARK: GH-103 TC12

    func test_GH103_TC12_미국지역이면기본통화가USD이고_12점50을넣으면1250으로저장되어_달러로보인다() {
        // Given: 기기 지역 통화가 USD
        XCTAssertEqual(AmountFormatter.defaultCurrency(locale: english), "USD")
        let sut = WishFormViewModel(
            config: .init(mode: .add(.wantToGet)),
            dependency: .init(
                wishRepository: wishRepository,
                notificationManager: notificationManager,
                logManager: logManager,
                userDefaults: userDefaults,
                linkMetadataProvider: linkMetadataProvider,
                linkPreviewCache: linkPreviewCache,
                photoStorage: photoStorage,
                linkPreviewDelay: nil,
                randomEmoji: { "🎲" },
                now: { Date() },
                defaultCurrency: { "USD" }
            )
        )
        sut.send(.inputTitle("Headphones"))

        // When: 치는 중인 "12." 을 지우지 않고 "12.50" 까지 받는다
        sut.send(.inputTargetAmount("12."))
        let typing = sut.state.targetAmountText
        sut.send(.inputTargetAmount("12.50"))
        sut.send(.tapSave)

        // Then
        XCTAssertEqual(typing, "12.")
        XCTAssertEqual(wishRepository.addedWishes.first?.currency, "USD")
        XCTAssertEqual(wishRepository.addedWishes.first?.targetAmount, 1250)
        XCTAssertEqual(AmountFormatter.money(1250, currency: "USD", locale: english), "$12.50")
        XCTAssertEqual(AmountFormatter.money(1200, currency: "USD", locale: english), "$12")
    }

    // MARK: GH-103 TC13

    func test_GH103_TC13_한국어원화금액표시가_예전과같다() {
        XCTAssertEqual(AmountFormatter.money(769_000, currency: "KRW", locale: korean), "769,000원")
        XCTAssertEqual(Strings.Detail.Saving.targetFormat(AmountFormatter.money(1_000_000, currency: "KRW", locale: korean)), "/ 1,000,000원")
        XCTAssertEqual(Strings.Detail.Saving.recordFormat(AmountFormatter.money(50_000, currency: "KRW", locale: korean)), "+50,000원")
        XCTAssertEqual(Strings.Detail.Saving.remainingFormat(AmountFormatter.money(10_000, currency: "KRW", locale: korean)), "10,000원 더 모으면 돼요!")
        XCTAssertEqual(AmountFormatter.unit(currency: "KRW", locale: korean), "원")
        XCTAssertEqual(AmountFormatter.quickAmounts(currency: "KRW"), [10_000, 50_000, 100_000])
    }

    // MARK: GH-103 TC14

    func test_GH103_TC14_저금기록이있는위시는_통화를바꿀수없다() {
        // Given: 원화 저금 기록이 있는 위시
        let wish = Wish(category: .wantToGet, title: "맥북", targetAmount: 1_000_000, currency: "KRW",
                        savings: [WishSaving(amount: 50_000)])
        let sut = makeEdit(wish)

        // When
        sut.send(.selectCurrency("USD"))

        // Then
        XCTAssertEqual(sut.state.currency, "KRW")
        XCTAssertEqual(sut.route, .toast(Strings.Write.TargetAmount.currencyLocked))
    }
}
