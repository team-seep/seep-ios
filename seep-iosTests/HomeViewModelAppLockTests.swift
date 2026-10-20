import XCTest
import Combine

@testable import seep_ios_dev

/// 홈 자물쇠 버튼 (GH-46 R-1 ~ R-3)
final class HomeViewModelAppLockTests: XCTestCase {
    private var sut: HomeViewModel!
    private var preference: Preference!
    private var authenticationManager: MockAuthenticationManager!
    private var logManager: MockLogManager!
    private var routes: [HomeViewModel.Route] = []
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        preference = Preference(name: "test-gh46-home-app-lock")
        authenticationManager = MockAuthenticationManager()
        logManager = MockLogManager()
        routes = []
    }

    override func tearDown() {
        sut = nil
        preference = nil
        authenticationManager = nil
        logManager = nil
        cancellables = []
        super.tearDown()
    }

    private func makeSut(isAppLockEnabled: Bool) {
        preference.isAppLockEnabled = isAppLockEnabled
        sut = HomeViewModel(dependency: .init(
            wishRepository: MockWishRepository(),
            preference: preference,
            notificationManager: MockNotificationManager(),
            logManager: logManager,
            authenticationManager: authenticationManager
        ))
        sut.output.route
            .sink { [weak self] in self?.routes.append($0) }
            .store(in: &cancellables)
    }

    private var appLockSheetViewModel: AppLockBottomSheetViewModel? {
        return routes.compactMap {
            if case .presentAppLockBottomSheet(let viewModel) = $0 { return viewModel }
            return nil
        }.last
    }

    // MARK: GH-46 TC1

    func test_GH46_TC1_잠금꺼짐_자물쇠를탭하면_잠그기시트를띄운다() {
        // Given
        makeSut(isAppLockEnabled: false)

        // When
        sut.headerViewModel.input.didTapAppLock.send(())

        // Then
        XCTAssertEqual(appLockSheetViewModel?.output.isEnabled, false)
    }

    func test_GH46_TC1_시트에서잠금을켜면_자물쇠가켜짐으로바뀐다() {
        // Given
        makeSut(isAppLockEnabled: false)
        XCTAssertFalse(sut.headerViewModel.output.isAppLockEnabled.value)
        sut.headerViewModel.input.didTapAppLock.send(())

        // When
        appLockSheetViewModel?.input.didTapConfirm.send(())

        // Then
        XCTAssertTrue(sut.headerViewModel.output.isAppLockEnabled.value)
    }

    // MARK: GH-46 TC8

    func test_GH46_TC8_잠금켜짐_자물쇠는켜짐으로시작하고_시트에서끄면_꺼짐으로바뀐다() {
        // Given
        makeSut(isAppLockEnabled: true)
        XCTAssertTrue(sut.headerViewModel.output.isAppLockEnabled.value)
        sut.headerViewModel.input.didTapAppLock.send(())

        // When
        appLockSheetViewModel?.input.didTapConfirm.send(())

        // Then
        XCTAssertEqual(appLockSheetViewModel?.output.isEnabled, true)
        XCTAssertFalse(sut.headerViewModel.output.isAppLockEnabled.value)
        XCTAssertFalse(preference.isAppLockEnabled)
    }

    // MARK: GH-46 TC12

    func test_GH46_TC12_홈자물쇠를탭하면_app_lock클릭로그가1건전송된다() {
        // Given
        makeSut(isAppLockEnabled: false)

        // When
        sut.headerViewModel.input.didTapAppLock.send(())

        // Then
        let appLockLogs = logManager.sentEvents.filter {
            $0.name == .click
                && $0.screen == .home
                && $0.parameters[ParameterName.objectId.rawValue] as? String == "app_lock"
        }
        XCTAssertEqual(appLockLogs.count, 1)
    }
}
