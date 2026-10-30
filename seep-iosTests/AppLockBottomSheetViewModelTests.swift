import XCTest
import Combine

@testable import seep_ios

/// 잠금 켜기·끄기 바텀시트 (GH-46 R-2 ~ R-4, R-11)
final class AppLockBottomSheetViewModelTests: XCTestCase {
    private var sut: AppLockBottomSheetViewModel!
    private var preference: Preference!
    private var authenticationManager: MockAuthenticationManager!
    private var logManager: MockLogManager!
    private var changes: [Bool] = []
    private var toasts: [String] = []
    private var dismissCount = 0
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test-gh46-app-lock-sheet")
        authenticationManager = MockAuthenticationManager()
        logManager = MockLogManager()
        changes = []
        toasts = []
        dismissCount = 0
    }

    override func tearDown() {
        sut = nil
        preference = nil
        authenticationManager = nil
        logManager = nil
        cancellables = []
        super.tearDown()
    }

    private func makeSut(isEnabled: Bool) {
        preference.isAppLockEnabled = isEnabled
        sut = AppLockBottomSheetViewModel(dependency: .init(
            preference: preference,
            authenticationManager: authenticationManager,
            logManager: logManager
        ))
        sut.output.didChangeAppLock
            .sink { [weak self] in self?.changes.append($0) }
            .store(in: &cancellables)
        sut.output.toast
            .sink { [weak self] in self?.toasts.append($0) }
            .store(in: &cancellables)
        sut.output.route
            .sink { [weak self] route in
                if case .dismiss = route { self?.dismissCount += 1 }
            }
            .store(in: &cancellables)
    }

    private func clickLogCount(objectId: String) -> Int {
        return logManager.sentEvents.filter {
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
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertTrue(preference.isAppLockEnabled)
        XCTAssertEqual(changes, [true])
        XCTAssertEqual(dismissCount, 1)
    }

    func test_GH46_TC1_잠금꺼짐_시트문구가잠그기다() {
        // Given
        authenticationManager.biometryResult = .faceID

        // When
        makeSut(isEnabled: false)

        // Then
        XCTAssertFalse(sut.output.isEnabled)
        XCTAssertEqual(sut.output.title, "싶을 나만 볼 수 있게\n잠가둘까요?")
        XCTAssertEqual(sut.output.confirmButtonTitle, "Face ID로 잠그기")
        XCTAssertEqual(sut.output.closeButtonTitle, "다음에 할게요")
    }

    // MARK: GH-46 TC2

    func test_GH46_TC2_잠금꺼짐_잠그기에서인증취소하면_꺼진채로시트가유지된다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.authenticateResult = false

        // When
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 1)
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertEqual(changes, [])
        XCTAssertEqual(dismissCount, 0)
    }

    func test_GH46_TC2_인증창이떠있는동안다시탭하면_인증을겹쳐요청하지않는다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.isAuthenticating = true

        // When
        sut.input.didTapConfirm.send(())

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
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
        XCTAssertEqual(toasts, ["기기 암호를 먼저 설정해 주세요"])
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertEqual(dismissCount, 0)
    }

    // MARK: GH-46 TC8

    func test_GH46_TC8_잠금켜짐_잠금끄기에서인증성공하면_잠금이꺼지고시트가닫힌다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = true

        // When
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 1)
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertEqual(changes, [false])
        XCTAssertEqual(dismissCount, 1)
    }

    func test_GH46_TC8_잠금켜짐_잠금끄기에서인증취소하면_켜진채로남는다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.authenticateResult = false

        // When
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertTrue(preference.isAppLockEnabled)
        XCTAssertEqual(changes, [])
        XCTAssertEqual(dismissCount, 0)
    }

    func test_GH46_TC8_잠금켜짐_시트문구가잠금끄기다() {
        // Given
        // When
        makeSut(isEnabled: true)

        // Then
        XCTAssertTrue(sut.output.isEnabled)
        XCTAssertEqual(sut.output.title, "지금 싶이\n잠겨 있어요")
        XCTAssertEqual(sut.output.confirmButtonTitle, "잠금 끄기")
        XCTAssertEqual(sut.output.closeButtonTitle, "닫기")
    }

    // MARK: GH-46 TC11

    func test_GH46_TC11_TouchID기기_시트문구가TouchID다() {
        // Given
        authenticationManager.biometryResult = .touchID

        // When
        makeSut(isEnabled: false)

        // Then
        XCTAssertEqual(sut.output.confirmButtonTitle, "Touch ID로 잠그기")
        XCTAssertEqual(sut.output.description, "앱을 열 때 Touch ID나 기기 암호를 물어봐요.\n홈 화면 위젯은 잠금과 상관없이 보여요.")
    }

    func test_GH46_TC11_생체인증이없는기기_시트문구가기기암호다() {
        // Given
        authenticationManager.biometryResult = .passcode

        // When
        makeSut(isEnabled: false)

        // Then
        XCTAssertEqual(sut.output.confirmButtonTitle, "기기 암호로 잠그기")
        XCTAssertEqual(sut.output.description, "앱을 열 때 기기 암호를 물어봐요.\n홈 화면 위젯은 잠금과 상관없이 보여요.")
    }

    // MARK: GH-46 TC12

    func test_GH46_TC12_잠금을켜면_enable_app_lock로그가1건전송된다() {
        // Given
        makeSut(isEnabled: false)

        // When
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertEqual(clickLogCount(objectId: "enable_app_lock"), 1)
        XCTAssertEqual(clickLogCount(objectId: "disable_app_lock"), 0)
    }

    func test_GH46_TC12_잠금을끄면_disable_app_lock로그가1건전송된다() {
        // Given
        makeSut(isEnabled: true)

        // When
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertEqual(clickLogCount(objectId: "disable_app_lock"), 1)
        XCTAssertEqual(clickLogCount(objectId: "enable_app_lock"), 0)
    }

    func test_GH46_TC12_인증을취소하면_로그를보내지않는다() {
        // Given
        makeSut(isEnabled: false)
        authenticationManager.authenticateResult = false

        // When
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertTrue(logManager.sentEvents.isEmpty)
    }

    // MARK: GH-46 TC13

    func test_GH46_TC13_잠금켜짐_기기암호가지워져인증불가면_잠금끄기는인증없이꺼진다() {
        // Given
        makeSut(isEnabled: true)
        authenticationManager.canAuthenticateResult = false

        // When
        sut.input.didTapConfirm.send(())

        // Then
        XCTAssertEqual(authenticationManager.authenticateCallCount, 0)
        XCTAssertFalse(preference.isAppLockEnabled)
        XCTAssertEqual(changes, [false])
        XCTAssertEqual(dismissCount, 1)
    }
}
