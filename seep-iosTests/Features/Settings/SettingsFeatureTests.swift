import XCTest

@testable import seep_ios_dev

/// 설정 탭 (GH-64 R-24 ~ R-29)
final class SettingsFeatureTests: ViewModelTestCase {
    private var preference: Preference!
    private var authenticationManager: MockAuthenticationManager!
    private var notificationManager: MockNotificationManager!

    private let deviceInfo = DeviceInfo(appVersion: "2.5.0", osVersion: "18.1", deviceModel: "iPhone17,1")

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test-gh64-settings")
        authenticationManager = MockAuthenticationManager()
        notificationManager = MockNotificationManager()
    }

    override func tearDown() {
        preference = nil
        authenticationManager = nil
        notificationManager = nil
        super.tearDown()
    }

    private func makeSut(appStoreID: String? = "1234567890", contactEmail: String? = "help@example.com") -> SettingsViewModel {
        SettingsViewModel(dependency: .init(
            preference: preference,
            authenticationManager: authenticationManager,
            notificationManager: notificationManager,
            logManager: logManager,
            deviceInfo: deviceInfo,
            appStoreID: appStoreID,
            contactEmail: contactEmail
        ))
    }

    private func rows(_ sut: SettingsViewModel) -> [SettingsRow] {
        sut.state.groups.flatMap(\.rows)
    }

    // MARK: GH-64 TC14

    func test_GH64_TC14_잠금스위치를켜고인증에성공하면_잠금이켜진다() {
        // Given
        preference.isAppLockEnabled = false
        let sut = makeSut()
        authenticationManager.authenticateResult = true

        // When
        sut.send(.tapAppLock)
        let sheet = AppLockSheetViewModel(dependency: .init(
            preference: preference,
            authenticationManager: authenticationManager,
            logManager: logManager
        ))
        sheet.send(.tapConfirm)
        sut.send(.appLockSheetDismissed)

        // Then
        XCTAssertEqual(sut.route, .appLockSheet)
        XCTAssertTrue(preference.isAppLockEnabled)
        XCTAssertTrue(sut.state.isAppLockEnabled)
    }

    func test_GH64_TC14_인증을취소하면_스위치가꺼짐으로돌아온다() {
        // Given
        preference.isAppLockEnabled = false
        let sut = makeSut()
        authenticationManager.authenticateResult = false

        // When
        sut.send(.tapAppLock)
        let sheet = AppLockSheetViewModel(dependency: .init(
            preference: preference,
            authenticationManager: authenticationManager,
            logManager: logManager
        ))
        sheet.send(.tapConfirm)
        sut.send(.appLockSheetDismissed)

        // Then
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertFalse(sut.state.isAppLockEnabled)
        XCTAssertTrue(rows(sut).contains(.appLock(
            title: "Face ID로 잠그기",
            description: "앱을 열 때 Face ID나 기기 암호로 확인해요",
            isOn: false
        )))
    }

    // MARK: GH-64 TC15

    func test_GH64_TC15_알림권한이거부면_꺼짐이고_누르면시스템설정을연다() {
        // Given
        notificationManager.authorizationStatusResult = .denied
        let sut = makeSut()

        // When
        sut.send(.onAppear)

        // Then
        waitUntil { sut.state.notificationStatus == .denied }
        XCTAssertTrue(rows(sut).contains(.notification(status: .denied)))

        // When
        sut.send(.tapNotification)

        // Then
        XCTAssertEqual(sut.route, .openURL(URL(string: "app-settings:")!))
        XCTAssertEqual(clickEvents(objectId: .notificationSetting).count, 1)
    }

    func test_GH64_TC15_알림권한이허용이면_켜짐이고_다시보일때다시읽는다() {
        // Given
        notificationManager.authorizationStatusResult = .authorized
        let sut = makeSut()

        // When
        sut.send(.onAppear)
        waitUntil { sut.state.notificationStatus == .authorized }
        notificationManager.authorizationStatusResult = .denied
        sut.send(.onAppear)

        // Then
        waitUntil { sut.state.notificationStatus == .denied }
        XCTAssertEqual(notificationManager.authorizationStatusCallCount, 2)
    }

    // MARK: GH-64 TC16

    func test_GH64_TC16_홈보기방식에서그리드를고르면_저장되고줄값이바뀐다() {
        // Given
        preference.viewType = .list
        let sut = makeSut()

        // When
        sut.send(.tapViewType)
        let route = sut.route
        sut.send(.selectViewType(.grid))

        // Then
        XCTAssertEqual(route, .viewTypeDialog)
        XCTAssertEqual(preference.viewType, .grid)
        XCTAssertTrue(rows(sut).contains(.viewType(.grid)))
        XCTAssertEqual(clickEvents(objectId: .viewTypeSetting).count, 1)
    }

    // MARK: GH-64 TC17

    func test_GH64_TC17_생체인증종류에따라_잠금줄이름이바뀐다() {
        // Given / When / Then
        XCTAssertEqual(SettingsMenuBuilder.lockTitle(biometry: .faceID), "Face ID로 잠그기")
        XCTAssertEqual(SettingsMenuBuilder.lockTitle(biometry: .touchID), "Touch ID로 잠그기")
        XCTAssertEqual(SettingsMenuBuilder.lockTitle(biometry: .passcode), "암호로 잠그기")
    }

    func test_GH64_TC17_설정그룹은_잠금과알림_보기_바로적기_정보순서다() {
        // Given / When
        let groups = SettingsMenuBuilder.groups(
            biometry: .faceID,
            isAppLockEnabled: true,
            notificationStatus: .authorized,
            viewType: .list,
            version: "2.5.0"
        )

        // Then
        XCTAssertEqual(groups.map(\.title), ["잠금과 알림", "보기", "바로 적기", "정보"])
        XCTAssertEqual(groups[3].rows, [.rateApp, .contact, .license, .version("2.5.0")])
    }

    // MARK: GH-64 TC18

    func test_GH64_TC18_메일앱을열수없으면_주소를알려주는토스트를띄운다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.contactUnavailable)

        // Then
        XCTAssertEqual(sut.route, .toast("메일 앱을 열 수 없어요. help@example.com 로 보내주세요"))
    }

    // MARK: GH-64 TC19

    func test_GH64_TC19_안내와라이선스는_탭안에화면을쌓는다() {
        // Given
        let sut = makeSut()

        // When / Then
        sut.send(.tapWidgetGuide)
        XCTAssertEqual(sut.route, .push(.widgetGuide))
        sut.send(.tapControlGuide)
        XCTAssertEqual(sut.route, .push(.controlGuide))
        sut.send(.tapLicense)
        XCTAssertEqual(sut.route, .push(.license))
    }

    // MARK: GH-64 TC301

    func test_GH64_TC301_버전줄은_번들버전을보여주고_누를수없다() {
        // Given / When
        let sut = makeSut()

        // Then
        XCTAssertEqual(rows(sut).last, .version("2.5.0"))
    }

    // MARK: GH-64 TC302

    func test_GH64_TC302_문의하기는_제목과버전정보가들어간mailto를연다() throws {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapContact)

        // Then
        guard case .openURL(let url) = sut.route else { return XCTFail("메일 링크가 없다") }
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, "help@example.com")
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(query["subject"], "[싶 문의]")
        XCTAssertTrue(query["body"]?.contains("앱 버전: 2.5.0") == true)
        XCTAssertTrue(query["body"]?.contains("iOS 버전: 18.1") == true)
        XCTAssertTrue(query["body"]?.contains("기기: iPhone17,1") == true)
        XCTAssertEqual(clickEvents(objectId: .contact).count, 1)
    }

    func test_GH64_TC302_문의주소가정해지지않았으면_링크를열지않는다() {
        // Given
        let sut = makeSut(contactEmail: nil)

        // When
        sut.send(.tapContact)

        // Then
        XCTAssertNil(sut.route)
    }

    func test_GH64_TC302_iOS버전문구는_패치가0이면뺀다() {
        // Given / When / Then
        XCTAssertEqual(DeviceInfo.osVersionText(OperatingSystemVersion(majorVersion: 18, minorVersion: 1, patchVersion: 0)), "18.1")
        XCTAssertEqual(DeviceInfo.osVersionText(OperatingSystemVersion(majorVersion: 18, minorVersion: 1, patchVersion: 2)), "18.1.2")
    }

    // MARK: GH-64 TC303

    func test_GH64_TC303_앱평가하기는_리뷰쓰기링크를열고_rate_app로그가간다() {
        // Given
        let sut = makeSut(appStoreID: "1234567890")

        // When
        sut.send(.tapRateApp)

        // Then
        XCTAssertEqual(sut.route, .openURL(URL(string: "itms-apps://apps.apple.com/app/id1234567890?action=write-review")!))
        XCTAssertEqual(clickEvents(objectId: .rateApp).count, 1)
    }

    // MARK: GH-64 TC304

    func test_GH64_TC304_설정항목을누르면_항목별클릭로그가1건씩간다() {
        // Given
        let sut = makeSut()
        let actions: [(SettingsViewModel.Action, LogObjectId)] = [
            (.tapAppLock, .appLock),
            (.tapNotification, .notificationSetting),
            (.tapViewType, .viewTypeSetting),
            (.tapWidgetGuide, .widgetGuide),
            (.tapControlGuide, .controlGuide),
            (.tapRateApp, .rateApp),
            (.tapContact, .contact),
            (.tapLicense, .license)
        ]

        for (action, objectId) in actions {
            // When
            sut.send(action)
            sut.send(.routeHandled)

            // Then
            let events = clickEvents(objectId: objectId)
            XCTAssertEqual(events.count, 1, "\(objectId)")
            XCTAssertEqual(events.first?.screen, .settings)
        }
    }

    func test_GH64_TC304_잠금줄로그에는_누를때켜져있었는지가붙는다() {
        // Given
        preference.isAppLockEnabled = true
        let sut = makeSut()

        // When
        sut.send(.tapAppLock)

        // Then
        XCTAssertEqual(clickEvents(objectId: .appLock).first?.extraParameters?[.enabled] as? Bool, true)
    }
}
