import XCTest

@testable import seep_ios

/// 잠금 켜기·끄기 시트 (GH-46 R-2 ~ R-4, R-11) — `AppLockBottomSheetViewModelTests`를 SwiftUI 시트 판으로 옮겼다.
/// 설정 탭 잠금 줄에서 연다 (GH-64 R-25)
final class AppLockSheetFeatureTests: ViewModelTestCase {
    private var sut: AppLockSheetViewModel!
    private var preference: Preference!
    private var authenticationManager: MockAuthenticationManager!

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test-gh64-app-lock-sheet")
        authenticationManager = MockAuthenticationManager()
    }

    override func tearDown() {
        sut = nil
        preference = nil
        authenticationManager = nil
        super.tearDown()
    }

    private func makeSut(isEnabled: Bool) {
        preference.isAppLockEnabled = isEnabled
        sut = AppLockSheetViewModel(dependency: .init(
            preference: preference,
            authenticationManager: authenticationManager,
            logManager: logManager
        ))
    }

    private func clickLogCount(objectId: String) -> Int {
        logManager.sentEvents.filter {
            $0.name == .click
                && $0.screen == .appLockBottomSheet
                && $0.parameters[ParameterName.objectId.rawValue] as? String == objectId
        }.count
    }

    // MARK: GH-46 TC1

    func test_GH46_TC1_잠금꺼짐_잠그기에서인증성공하면_잠금이켜지고시트가닫힌다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.authenticateResult = true

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertTrue(preference.isAppLockEnabled)
        XCTAssertEqual(sut.route, .dismiss(changedTo: true))
    }

    func test_GH46_TC1_잠금꺼짐_시트문구가잠그기다() {
        // Given
        authenticationManager.biometryResult = .faceID

        // When
        makeSut(isEnabled: false)

        // Then
        XCTAssertFalse(sut.state.isEnabled)
        XCTAssertEqual(sut.state.title, "싶을 나만 볼 수 있게\n잠가둘까요?")
        XCTAssertEqual(sut.state.confirmButtonTitle, "Face ID로 잠그기")
        XCTAssertEqual(sut.state.closeButtonTitle, "다음에 할게요")
    }

    // MARK: GH-46 TC2

    func test_GH46_TC2_잠금꺼짐_잠그기에서인증취소하면_꺼진채로시트가유지된다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.authenticateResult = false

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 1)
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertNil(sut.route)
    }

    func test_GH46_TC2_인증창이떠있는동안다시탭하면_인증을겹쳐요청하지않는다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.isAuthenticating = true

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
        XCTAssertFalse(preference.isAppLockEnabled)
    }

    // MARK: GH-46 TC3

    func test_GH46_TC3_기기암호가없으면_인증없이토스트를띄우고_꺼진채로둔다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.canAuthenticateResult = false

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
        XCTAssertEqual(sut.route, .toast("기기 암호를 먼저 설정해 주세요"))
        XCTAssertFalse(preference.isAppLockEnabled)
    }

    // MARK: GH-46 TC8

    func test_GH46_TC8_잠금켜짐_잠금끄기에서인증성공하면_잠금이꺼지고시트가닫힌다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = true

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 1)
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertEqual(sut.route, .dismiss(changedTo: false))
    }

    func test_GH46_TC8_잠금켜짐_잠금끄기에서인증취소하면_켜진채로남는다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertTrue(preference.isAppLockEnabled)
        XCTAssertNil(sut.route)
    }

    func test_GH46_TC8_잠금켜짐_시트문구가잠금끄기다() {
        // Given
        // When
        makeSut(isEnabled: true)

        // Then
        XCTAssertTrue(sut.state.isEnabled)
        XCTAssertEqual(sut.state.title, "지금 싶이\n잠겨 있어요")
        XCTAssertEqual(sut.state.confirmButtonTitle, "잠금 끄기")
        XCTAssertEqual(sut.state.closeButtonTitle, "닫기")
    }

    // MARK: GH-46 TC11

    func test_GH46_TC11_TouchID기기_시트문구가TouchID다() {
        // Given
        authenticationManager.biometryResult = .touchID

        // When
        makeSut(isEnabled: false)

        // Then
        XCTAssertEqual(sut.state.confirmButtonTitle, "Touch ID로 잠그기")
        XCTAssertEqual(sut.state.description, "앱을 열 때 Touch ID나 기기 암호를 물어봐요.\n홈 화면 위젯은 잠금과 상관없이 보여요.")
    }

    func test_GH46_TC11_생체인증이없는기기_시트문구가기기암호다() {
        // Given
        authenticationManager.biometryResult = .passcode

        // When
        makeSut(isEnabled: false)

        // Then
        XCTAssertEqual(sut.state.confirmButtonTitle, "기기 암호로 잠그기")
        XCTAssertEqual(sut.state.description, "앱을 열 때 기기 암호를 물어봐요.\n홈 화면 위젯은 잠금과 상관없이 보여요.")
    }

    // MARK: GH-46 TC12

    func test_GH46_TC12_잠금을켜면_enable_app_lock로그가1건전송된다() {
        // Given
        makeSut(isEnabled: false)

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertEqual(clickLogCount(objectId: "enable_app_lock"), 1)
        XCTAssertEqual(clickLogCount(objectId: "disable_app_lock"), 0)
    }

    func test_GH46_TC12_잠금을끄면_disable_app_lock로그가1건전송된다() {
        // Given
        makeSut(isEnabled: true)

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertEqual(clickLogCount(objectId: "disable_app_lock"), 1)
        XCTAssertEqual(clickLogCount(objectId: "enable_app_lock"), 0)
    }

    func test_GH46_TC12_인증을취소하면_로그를보내지않는다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.authenticateResult = false

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    // MARK: GH-46 TC13

    func test_GH46_TC13_잠금켜짐_기기암호가지워져인증불가면_잠금끄기는인증없이꺼진다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.canAuthenticateResult = false

        // When
        sut.send(.tapConfirm)

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertEqual(sut.route, .dismiss(changedTo: false))
    }

    // MARK: GH-64 TC1101

    func test_GH64_TC1101_꺼짐켜짐에따라_켜기끄기문구가바뀐다() {
        // Given / When
        makeSut(isEnabled: false)
        let enableState = sut.state
        makeSut(isEnabled: true)
        let disableState = sut.state

        // Then
        XCTAssertFalse(enableState.isEnabled)
        XCTAssertEqual(enableState.titleBold, "잠가둘까요?")
        XCTAssertTrue(disableState.isEnabled)
        XCTAssertEqual(disableState.titleBold, "잠겨 있어요")
    }

    func test_GH64_TC1101_닫기를누르면_바꾸지않고닫는다() {
        // Given
        makeSut(isEnabled: false)

        // When
        sut.send(.tapClose)

        // Then
        XCTAssertEqual(sut.route, .dismiss(changedTo: nil))
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
    }
}
