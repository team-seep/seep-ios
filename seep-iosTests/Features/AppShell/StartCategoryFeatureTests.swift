import XCTest

@testable import seep_ios

/// 시작 카테고리 (GH-86 R-1, R-2)
final class StartCategoryFeatureTests: ViewModelTestCase {
    private let suiteName = "test-gh86-start-category"
    private var preference: Preference!

    override func setUp() {
        super.setUp()
        preference = Preference(name: suiteName)
    }

    override func tearDown() {
        preference = nil
        super.tearDown()
    }

    private func launchRouter() -> AppRouter {
        AppRouter(dependency: .init(wishRepository: MockWishRepository(), deepLinkStore: preference))
    }

    // MARK: GH-86 TC1

    func test_GH86_TC1_시작카테고리가갖고싶어요면_새로켤때홈이갖고싶어요로열린다() {
        // Given
        preference.startCategory = .wantToGet
        preference.lastHomeCategory = .wantToGo

        // When
        let router = launchRouter()

        // Then
        XCTAssertEqual(router.homeCategory, .wantToGet)
    }

    // MARK: GH-86 TC2

    func test_GH86_TC2_마지막으로본카테고리면_끄고켜도마지막에본탭으로열린다() {
        // Given
        let first = launchRouter()
        first.homeCategory = .wantToGo

        // When
        let relaunched = launchRouter()

        // Then
        XCTAssertNil(preference.startCategory)
        XCTAssertEqual(relaunched.homeCategory, .wantToGo)
    }

    // MARK: GH-86 TC3

    func test_GH86_TC3_위젯으로열면_위젯대상이시작카테고리보다먼저다() {
        // Given
        preference.startCategory = .wantToDo
        let router = launchRouter()

        // When
        router.mainDidAppear()
        let handled = router.handle(.add(.wantToGet))

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(router.writeCategory, .wantToGet)
    }

    // MARK: GH-86 TC9

    func test_GH86_TC9_시작카테고리를고르면_저장하고select_start_category로그가간다() {
        // Given
        let sut = SettingsViewModel(dependency: .init(
            preference: preference,
            authenticationManager: MockAuthenticationManager(),
            notificationManager: MockNotificationManager(),
            logManager: logManager,
            deviceInfo: DeviceInfo(appVersion: "2.5.1", osVersion: "27.0", deviceModel: "iPhone18,1"),
            appStoreID: nil,
            contactEmail: nil,
            pasteboard: MockPasteboard()
        ))
        sut.send(.onAppear)

        // When
        sut.send(.tapStartCategory)
        let route = sut.route
        sut.send(.selectStartCategory(.wantToGet))

        // Then
        XCTAssertEqual(route, .startCategoryDialog)
        XCTAssertEqual(preference.startCategory, .wantToGet)
        XCTAssertTrue(sut.state.groups.flatMap(\.rows).contains(.startCategory(.wantToGet)))
        let events = clickEvents(objectId: .selectStartCategory)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, Category.wantToGet.rawValue)
    }
}
