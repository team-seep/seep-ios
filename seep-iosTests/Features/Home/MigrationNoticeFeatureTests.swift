import XCTest

@testable import seep_ios_dev

/// 복구 결과를 정해 두는 대역
private final class StubLegacyImportRecovery: LegacyImportRecovering {
    var problem: LegacyImportProblem?
    var retryResult: Result<Int, Error> = .success(0)
    private(set) var retryCount = 0

    init(problem: LegacyImportProblem?) {
        self.problem = problem
    }

    func currentProblem() -> LegacyImportProblem? {
        problem
    }

    func retry() async -> Result<Int, Error> {
        retryCount += 1
        if case .success = retryResult {
            problem = nil
        }
        return retryResult
    }
}

/// 홈 "예전 위시를 불러오지 못했어요" 카드 (GH-96 R-9 ~ R-13)
final class MigrationNoticeFeatureTests: ViewModelTestCase {
    private let device = DeviceInfo(appVersion: "2.6.0", osVersion: "26.0", deviceModel: "iPhone18,1")

    private func makeViewModel(
        recovery: StubLegacyImportRecovery,
        contactEmail: String? = "seep@example.com"
    ) -> MigrationNoticeViewModel {
        MigrationNoticeViewModel(dependency: .init(
            recovery: recovery,
            logManager: logManager,
            contactEmail: contactEmail,
            deviceInfo: device
        ))
    }

    private var impressionEvents: [any LogEventType] {
        logManager.sentEvents.filter { event in
            event.name == .impression && (event.extraParameters?[.objectId] as? LogObjectId) == .migrationNotice
        }
    }

    // MARK: GH-96 TC13

    func test_GH96_TC13_1회이전이실패하면_카드에다시시도와문의하기가보인다() {
        // Given
        let viewModel = makeViewModel(recovery: StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2")))

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertEqual(viewModel.state.problem, .importFailed(errorType: "io.realm:2"))
        XCTAssertEqual(viewModel.state.message, Strings.Home.MigrationNotice.message)
        XCTAssertTrue(viewModel.state.isRetryVisible)
        XCTAssertTrue(viewModel.state.isContactVisible)
        XCTAssertNil(viewModel.route)
    }

    // MARK: GH-96 TC14

    func test_GH96_TC14_다시시도가성공하면_카드가사라지고_불러온개수토스트와함께목록을다시읽는다() {
        // Given
        let recovery = StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2"))
        recovery.retryResult = .success(3)
        let viewModel = makeViewModel(recovery: recovery)
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapRetry)

        // Then
        XCTAssertTrue(viewModel.state.isRetrying)
        waitUntil { viewModel.route != nil }
        XCTAssertEqual(viewModel.route, .restored(toast: Strings.Home.MigrationNotice.retrySuccessFormat(3)))
        XCTAssertNil(viewModel.state.problem)
        XCTAssertFalse(viewModel.state.isRetrying)
    }

    func test_GH96_TC14_위젯이먼저이전을끝내불러온수가0이면_토스트없이목록만다시읽는다() {
        // Given
        let recovery = StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2"))
        recovery.retryResult = .success(0)
        let viewModel = makeViewModel(recovery: recovery)
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapRetry)

        // Then
        waitUntil { viewModel.route != nil }
        XCTAssertEqual(viewModel.route, .restored(toast: nil))
    }

    // MARK: GH-96 TC15

    func test_GH96_TC15_다시시도가또실패하면_카드가남고실패토스트가뜬다() {
        // Given
        let recovery = StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2"))
        recovery.retryResult = .failure(NSError(domain: "io.realm", code: 2))
        let viewModel = makeViewModel(recovery: recovery)
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapRetry)

        // Then
        waitUntil { viewModel.route != nil }
        XCTAssertEqual(viewModel.route, .toast(Strings.Home.MigrationNotice.retryFailure))
        XCTAssertNotNil(viewModel.state.problem)
        XCTAssertFalse(viewModel.state.isRetrying)
    }

    func test_GH96_TC15_다시시도중에는_다시눌러도한번만돈다() {
        // Given
        let recovery = StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2"))
        let viewModel = makeViewModel(recovery: recovery)
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapRetry)
        viewModel.send(.tapRetry)

        // Then
        waitUntil { viewModel.route != nil }
        XCTAssertEqual(recovery.retryCount, 1)
    }

    // MARK: GH-96 TC17

    func test_GH96_TC17_문의하기를누르면_에러종류가들어간문의메일이열린다() throws {
        // Given
        let viewModel = makeViewModel(recovery: StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2")))
        viewModel.send(.onAppear)

        // When
        viewModel.send(.tapContact)

        // Then
        guard case .openURL(let url) = viewModel.route else {
            return XCTFail("문의 메일을 열어야 한다")
        }
        XCTAssertEqual(url.scheme, "mailto")
        let body = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "body" }?.value)
        XCTAssertTrue(body.contains(Strings.Home.MigrationNotice.contactErrorFormat("io.realm:2")))
        XCTAssertTrue(body.contains("2.6.0"))
    }

    func test_GH96_TC17_문의메일이없는빌드에서는_문의하기버튼이없다() {
        // Given
        let viewModel = makeViewModel(recovery: StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2")), contactEmail: nil)

        // When
        viewModel.send(.onAppear)
        viewModel.send(.tapContact)

        // Then
        XCTAssertFalse(viewModel.state.isContactVisible)
        XCTAssertNil(viewModel.route)
    }

    // MARK: GH-96 TC18

    func test_GH96_TC18_DB를열지못하면_재실행안내만보이고다시시도는없다() {
        // Given
        let recovery = StubLegacyImportRecovery(problem: .databaseUnavailable)
        let viewModel = makeViewModel(recovery: recovery)

        // When
        viewModel.send(.onAppear)
        viewModel.send(.tapRetry)

        // Then
        XCTAssertEqual(viewModel.state.message, Strings.Home.MigrationNotice.messageRestart)
        XCTAssertFalse(viewModel.state.isRetryVisible)
        XCTAssertEqual(recovery.retryCount, 0)
    }

    // MARK: GH-96 TC19

    func test_GH96_TC19_이전이성공했거나신규설치면_카드가없다() {
        // Given
        let viewModel = makeViewModel(recovery: StubLegacyImportRecovery(problem: nil))

        // When
        viewModel.send(.onAppear)

        // Then
        XCTAssertNil(viewModel.state.problem)
        XCTAssertTrue(impressionEvents.isEmpty)
    }

    // MARK: GH-96 TC20

    func test_GH96_TC20_카드노출과다시시도문의하기가_노출클릭이벤트로남는다() {
        // Given
        let viewModel = makeViewModel(recovery: StubLegacyImportRecovery(problem: .importFailed(errorType: "io.realm:2")))

        // When
        viewModel.send(.onAppear)
        viewModel.send(.onAppear)
        viewModel.send(.tapContact)
        viewModel.send(.routeHandled)
        viewModel.send(.tapRetry)

        // Then
        XCTAssertEqual(impressionEvents.count, 1)
        XCTAssertEqual(impressionEvents.first?.parameters["screen"] as? String, "home")
        XCTAssertEqual(clickEvents(objectId: .migrationContact).count, 1)
        XCTAssertEqual(clickEvents(objectId: .migrationRetry).count, 1)
        waitUntil { viewModel.route != nil }
    }
}
