import XCTest

@testable import seep_ios

/// 설정 "화면 모드" (GH-85 R-3)
final class AppearanceFeatureTests: ViewModelTestCase {
    private var preference: Preference!

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test-gh85-appearance")
    }

    override func tearDown() {
        preference = nil
        super.tearDown()
    }

    private func makeSut() -> SettingsViewModel {
        SettingsViewModel(dependency: .init(
            preference: preference,
            authenticationManager: MockAuthenticationManager(),
            notificationManager: MockNotificationManager(),
            logManager: logManager,
            deviceInfo: DeviceInfo(appVersion: "2.5.1", osVersion: "27.0", deviceModel: "iPhone18,1"),
            appStoreID: nil,
            contactEmail: nil,
            pasteboard: MockPasteboard()
        ))
    }

    private func appearanceRow(_ sut: SettingsViewModel) -> SettingsRow? {
        sut.state.groups.flatMap(\.rows).first { $0.id == "appearance" }
    }

    // MARK: GH-85 TC1

    func test_GH85_TC1_기본값은시스템설정따르기이고_앱에화면모드를강제하지않는다() {
        // Given / When
        let sut = makeSut()
        sut.send(.onAppear)

        // Then
        XCTAssertEqual(preference.appearance, .system)
        XCTAssertNil(AppAppearance.system.colorScheme)
        XCTAssertEqual(appearanceRow(sut), .appearance(.system))
    }

    // MARK: GH-85 TC2

    func test_GH85_TC2_라이트나다크를고르면_그화면모드로고정된다() {
        // Given
        let sut = makeSut()
        sut.send(.onAppear)

        // When
        sut.send(.tapAppearance)
        let route = sut.route
        sut.send(.routeHandled)
        sut.send(.selectAppearance(.dark))

        // Then
        XCTAssertEqual(route, .appearanceDialog)
        XCTAssertEqual(preference.appearance, .dark)
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)
        XCTAssertEqual(appearanceRow(sut), .appearance(.dark))
    }

    // MARK: GH-85 TC3

    func test_GH85_TC3_고른화면모드는_다시켜도유지된다() {
        // Given
        makeSut().send(.selectAppearance(.light))

        // When
        let reopened = makeSut()
        reopened.send(.onAppear)

        // Then
        XCTAssertEqual(reopened.state.appearance, .light)
        XCTAssertEqual(UserDefaults(suiteName: "test-gh85-appearance")?.string(forKey: AppAppearance.storageKey), "light")
    }

    // MARK: GH-85 TC6

    func test_GH85_TC6_화면모드를고르면_select_appearance클릭로그가type과함께한번전송된다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.selectAppearance(.dark))

        // Then
        let events = clickEvents(objectId: .selectAppearance)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .settings)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, "dark")
    }
}
