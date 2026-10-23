import XCTest

@testable import seep_ios_dev

/// 잠금 화면과 생명주기 (GH-46 R-5 ~ R-7, R-11) — `AppLockViewModelTests`(UIKit 윈도우)를 SwiftUI 오버레이 판으로 옮겼다.
/// UIKit 생명주기 알림은 `scenePhase` 전이로 바뀐다: willResignActive = active→inactive, didEnterBackground = →background,
/// willEnterForeground = background→inactive, didBecomeActive = →active
final class AppLockOverlayFeatureTests: ViewModelTestCase {
    private var sut: AppLockOverlayViewModel!
    private var preference: Preference!
    private var authenticationManager: MockAuthenticationManager!
    private var now = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test-gh64-app-lock-overlay-feature")
        authenticationManager = MockAuthenticationManager()
        now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    override func tearDown() {
        sut = nil
        preference = nil
        authenticationManager = nil
        super.tearDown()
    }

    private func makeSut(isEnabled: Bool) {
        preference.isAppLockEnabled = isEnabled
        sut = AppLockOverlayViewModel(dependency: .init(
            preference: preference,
            authenticationManager: authenticationManager,
            logManager: logManager,
            now: { [unowned self] in self.now }
        ))
    }

    /// 콜드 스타트: 활성화된 뒤 스플래시가 끝나 메인이 뜬다
    private func launch() {
        sut.send(.phaseChanged(.active))
        sut.send(.mainDidAppear)
    }

    /// 홈 화면으로 나갔다가 `seconds` 뒤 돌아온다
    private func leaveAndReturn(after seconds: TimeInterval) {
        sut.send(.phaseChanged(.inactive))
        sut.send(.phaseChanged(.background))
        now = now.addingTimeInterval(seconds)
        sut.send(.phaseChanged(.inactive))
        sut.send(.phaseChanged(.active))
    }

    private var unlockLogCount: Int {
        logManager.sentEvents.filter {
            $0.name == .click
                && $0.screen == .appLock
                && $0.parameters[ParameterName.objectId.rawValue] as? String == "unlock_app"
        }.count
    }

    // MARK: GH-46 TC4

    func test_GH46_TC4_잠금켜짐_콜드스타트하면_잠금화면이뜨고_인증을자동요청한다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false

        // When
        launch()

        // Then
        XCTAssertEqual(sut.state.lockState, .locked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, 1)
    }

    func test_GH46_TC4_잠금켜짐_콜드스타트에서인증성공하면_잠금이풀린다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = true

        // When
        launch()

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
    }

    func test_GH46_TC4_잠금켜짐_스플래시중에는_잠그지않는다() {
        // Given
        makeSut(isEnabled: true)

        // When
        sut.send(.phaseChanged(.inactive))
        sut.send(.phaseChanged(.active))

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
    }

    // MARK: GH-46 TC5

    func test_GH46_TC5_잠금켜짐_백그라운드30초후복귀하면_잠금화면이뜨지않는다() {
        // Given
        makeSut(isEnabled: true)
        launch()
        let callCountAfterLaunch = authenticationManager.authenticateCallCount

        // When
        leaveAndReturn(after: 30)

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, callCountAfterLaunch)
    }

    // MARK: GH-46 TC6

    func test_GH46_TC6_잠금켜짐_백그라운드61초후복귀하면_잠금화면이뜨고_인증을자동요청한다() {
        // Given
        makeSut(isEnabled: true)
        launch()
        authenticationManager.authenticateResult = false
        let callCountAfterLaunch = authenticationManager.authenticateCallCount

        // When
        leaveAndReturn(after: 61)

        // Then
        XCTAssertEqual(sut.state.lockState, .locked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, callCountAfterLaunch + 1)
    }

    // MARK: GH-46 TC7

    func test_GH46_TC7_잠금화면에서인증취소하면_잠금화면이유지되고_자동으로다시묻지않는다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false
        launch()

        // When: 인증 창이 닫히며 앱이 다시 활성화된다
        sut.send(.phaseChanged(.inactive))
        sut.send(.phaseChanged(.active))

        // Then
        XCTAssertEqual(sut.state.lockState, .locked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, 1)
    }

    func test_GH46_TC7_잠금화면에서인증취소후_열기버튼으로다시시도할수있다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false
        launch()

        // When
        authenticationManager.authenticateResult = true
        sut.send(.tapUnlock)

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 2)
        XCTAssertEqual(sut.state.lockState, .unlocked)
    }

    // MARK: GH-46 TC8

    func test_GH46_TC8_잠금꺼짐_콜드스타트와61초후복귀에_묻지않는다() {
        // Given
        makeSut(isEnabled: false)

        // When
        launch()
        leaveAndReturn(after: 61)

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
    }

    // MARK: GH-46 TC9

    func test_GH46_TC9_잠금켜짐_비활성화되면_버튼없는덮개를씌운다() {
        // Given
        makeSut(isEnabled: true)
        launch()

        // When
        sut.send(.phaseChanged(.inactive))

        // Then
        XCTAssertEqual(sut.state.lockState, .covered)
    }

    func test_GH46_TC9_앱이띄운인증창으로비활성화되면_덮지않는다() {
        // Given
        makeSut(isEnabled: true)
        launch()
        authenticationManager.isAuthenticating = true

        // When
        sut.send(.phaseChanged(.inactive))

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
    }

    func test_GH46_TC9_잠금꺼짐_비활성화되어도_덮지않는다() {
        // Given
        makeSut(isEnabled: false)
        launch()

        // When
        sut.send(.phaseChanged(.inactive))

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
    }

    // MARK: GH-46 TC11

    func test_GH46_TC11_TouchID기기_잠금화면문구가TouchID다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.biometryResult = .touchID
        authenticationManager.authenticateResult = false

        // When
        launch()

        // Then
        XCTAssertEqual(sut.state.description, "Touch ID로 확인하면 열려요")
        XCTAssertEqual(sut.state.unlockButtonTitle, "Touch ID로 열기")
    }

    func test_GH46_TC11_생체인증이없는기기_잠금화면문구가기기암호다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.biometryResult = .passcode
        authenticationManager.authenticateResult = false

        // When
        launch()

        // Then
        XCTAssertEqual(sut.state.description, "기기 암호로 확인하면 열려요")
        XCTAssertEqual(sut.state.unlockButtonTitle, "기기 암호로 열기")
    }

    // MARK: GH-46 TC12

    func test_GH46_TC12_잠금화면에서인증성공하면_unlock_app로그가1건전송된다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false
        launch()

        // When
        authenticationManager.authenticateResult = true
        sut.send(.tapUnlock)

        // Then
        XCTAssertEqual(unlockLogCount, 1)
    }

    func test_GH46_TC12_잠금화면에서인증실패하면_unlock_app로그를보내지않는다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false

        // When
        launch()
        sut.send(.tapUnlock)

        // Then
        XCTAssertEqual(unlockLogCount, 0)
    }

    // MARK: GH-46 TC13

    func test_GH46_TC13_잠금켜짐_기기암호가지워져인증불가면_콜드스타트와61초후복귀에_잠그지않는다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.canAuthenticateResult = false

        // When
        launch()
        leaveAndReturn(after: 61)

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
    }

    // MARK: GH-64 TC1102

    func test_GH64_TC1102_잠긴상태에서인증실패하면_잠김이유지되고_다시시도할수있다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false
        launch()

        // When
        sut.send(.tapUnlock)

        // Then
        XCTAssertEqual(sut.state.lockState, .locked)
        XCTAssertEqual(authenticationManager.authenticateCallCount, 2)

        // When
        authenticationManager.authenticateResult = true
        sut.send(.tapUnlock)

        // Then
        XCTAssertEqual(sut.state.lockState, .unlocked)
    }
}
