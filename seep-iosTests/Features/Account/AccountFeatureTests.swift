import XCTest

@testable import seep_ios

/// 계정 동작이 일어난 순서 (TC-19 삭제 순서 단언용)
private final class AccountCallLog {
    var calls: [String] = []
}

private final class MockAccountManager: AccountManagerProtocol {
    let log: AccountCallLog
    var currentAccount: Account?
    var signInResult: Result<Account, Error> = .success(Account(uid: "uid-1", email: "a@privaterelay.appleid.com", createdAt: nil))
    var deleteError: Error?
    private(set) var signOutCallCount = 0

    init(log: AccountCallLog) {
        self.log = log
    }

    func makeNonce() -> AppleSignInNonce {
        AppleSignInNonce(raw: "raw", sha256: "hashed")
    }

    func signIn(with credential: AppleCredential, nonce: AppleSignInNonce) async throws -> Account {
        log.calls.append("signIn")
        let account = try signInResult.get()
        currentAccount = account
        return account
    }

    func signOut() throws {
        signOutCallCount += 1
        currentAccount = nil
    }

    func reauthenticate(with credential: AppleCredential, nonce: AppleSignInNonce) async throws {
        log.calls.append("reauthenticate")
    }

    func revokeAppleToken(authorizationCode: String) async throws {
        log.calls.append("revoke:\(authorizationCode)")
    }

    func deleteUser() async throws {
        if let deleteError { throw deleteError }
        log.calls.append("deleteUser")
        currentAccount = nil
    }
}

private struct MockRemoteDataEraser: RemoteAccountDataEraser {
    let log: AccountCallLog

    func eraseAll(uid: String) async throws {
        log.calls.append("eraseServerData:\(uid)")
    }
}

private final class MockNetwork: NetworkStatusProviding {
    var isConnected = true
}

private struct SyncFlagRemoteConfig: RemoteConfigRepository {
    let isSyncEnabled: Bool

    func fetchForceUpdateVersion() async -> Result<String, Error> { .success("") }
    func fetchAndActivate() async {}
    func fetchYearReviewPeriod() -> YearReviewPeriod? { nil }
    func fetchLegacyRealmReimportToken() -> String { "" }
    func fetchSyncEnabled() -> Bool { isSyncEnabled }
}

/// 마이 탭 계정 카드·계정 화면 (GH-93 R-24 ~ R-30)
final class AccountFeatureTests: ViewModelTestCase {
    private var callLog: AccountCallLog!
    private var accountManager: MockAccountManager!
    private var wishRepository: MockWishRepository!
    private var notificationManager: MockNotificationManager!
    private var photoStorage: MockWishPhotoStorage!
    private var network: MockNetwork!

    private let credential = AppleCredential(idToken: "token", authorizationCode: "code-1", fullName: nil)
    private let member = Account(uid: "uid-1", email: "a@privaterelay.appleid.com", createdAt: nil)

    override func setUp() {
        super.setUp()
        callLog = AccountCallLog()
        accountManager = MockAccountManager(log: callLog)
        wishRepository = MockWishRepository()
        notificationManager = MockNotificationManager()
        photoStorage = MockWishPhotoStorage()
        network = MockNetwork()
    }

    override func tearDown() {
        callLog = nil
        accountManager = nil
        wishRepository = nil
        notificationManager = nil
        photoStorage = nil
        network = nil
        super.tearDown()
    }

    private func makeSut(isSyncEnabled: Bool = true, signedIn: Bool = false) -> AccountViewModel {
        accountManager.currentAccount = signedIn ? member : nil
        let sut = AccountViewModel(dependency: .init(
            accountManager: accountManager,
            remoteDataEraser: MockRemoteDataEraser(log: callLog),
            wishRepository: wishRepository,
            notificationManager: notificationManager,
            photoStorage: photoStorage,
            network: network,
            remoteConfigRepository: SyncFlagRemoteConfig(isSyncEnabled: isSyncEnabled),
            logManager: logManager
        ))
        sut.send(.onAppear)
        return sut
    }

    private func customEvents(_ name: EventName) -> [any LogEventType] {
        logManager.sentEvents.filter { $0.name == name }
    }

    private func makeWish(id: String) -> Wish {
        Wish(id: id, emoji: "🎧", category: .wantToGet, title: "에어팟", endDate: nil, memo: "", isSuccess: false, photoFileName: "")
    }

    // MARK: TC-14

    func test_GH93_TC14_Apple로계속하기를누르면_로그인시트를요청하고_클릭로그가1건간다() {
        // Given
        let sut = makeSut()

        // When
        sut.send(.tapSignIn)

        // Then
        XCTAssertEqual(sut.route, .requestAppleAuthorization(nonce: "hashed"))
        XCTAssertTrue(sut.state.isWorking)
        let clicks = clickEvents(objectId: .accountSignIn)
        XCTAssertEqual(clicks.count, 1)
        XCTAssertEqual(clicks.first?.screen, .settings)
    }

    // MARK: TC-15

    func test_GH93_TC15_Apple로그인을취소하면_비회원그대로이고_오류를띄우지않는다() {
        // Given
        let sut = makeSut()
        sut.send(.tapSignIn)
        sut.send(.routeHandled)

        // When
        sut.send(.appleAuthorizationFailed(isCanceled: true))

        // Then
        XCTAssertNil(sut.state.account)
        XCTAssertFalse(sut.state.isWorking)
        XCTAssertNil(sut.route)
        XCTAssertTrue(callLog.calls.isEmpty)
    }

    func test_GH93_TC15_취소가아닌실패면_오류토스트를띄운다() {
        // Given
        let sut = makeSut()
        sut.send(.tapSignIn)
        sut.send(.routeHandled)

        // When
        sut.send(.appleAuthorizationFailed(isCanceled: false))

        // Then
        XCTAssertNil(sut.state.account)
        XCTAssertEqual(sut.route, .toast(Strings.Account.Error.signIn))
    }

    // MARK: TC-16

    func test_GH93_TC16_로그인에성공하면_회원카드가되고_account_sign_in이벤트가1건간다() {
        // Given
        let sut = makeSut()
        sut.send(.tapSignIn)
        sut.send(.routeHandled)

        // When
        sut.send(.appleAuthorized(credential))

        // Then
        waitUntil { sut.state.account == self.member }
        XCTAssertFalse(sut.state.isWorking)
        XCTAssertEqual(sut.route, .toast(Strings.Account.Toast.signedIn))
        XCTAssertEqual(customEvents(.accountSignIn).count, 1)
    }

    func test_GH93_TC16_Apple서버로그인이실패하면_비회원그대로_오류토스트() {
        // Given
        accountManager.signInResult = .failure(AccountError.failed("network"))
        let sut = makeSut()
        sut.send(.tapSignIn)
        sut.send(.routeHandled)

        // When
        sut.send(.appleAuthorized(credential))

        // Then
        waitUntil { sut.route == .toast(Strings.Account.Error.signIn) }
        XCTAssertNil(sut.state.account)
        XCTAssertTrue(customEvents(.accountSignIn).isEmpty)
    }

    // MARK: TC-17

    func test_GH93_TC17_로그아웃기본선택은_이기기에싶남기기다() {
        XCTAssertEqual(AccountViewModel.logoutChoices.first, .keep)
    }

    func test_GH93_TC17_남기기로로그아웃하면_로컬위시를지우지않고_비회원이된다() {
        // Given
        let sut = makeSut(signedIn: true)
        sut.send(.tapLogout)
        XCTAssertEqual(sut.state.dialog, .logout)

        // When
        sut.send(.selectLogout(.keep))

        // Then
        XCTAssertEqual(accountManager.signOutCallCount, 1)
        XCTAssertEqual(wishRepository.eraseAllLocalWishesCallCount, 0)
        XCTAssertNil(sut.state.account)
        XCTAssertNil(sut.state.dialog)
        XCTAssertEqual(sut.route, .popAccount)
        sut.send(.routeHandled)
        XCTAssertEqual(sut.route, .toast(Strings.Account.Toast.signedOut))
        XCTAssertEqual(customEvents(.accountSignOut).first?.extraParameters?[.type] as? String, "keep")
    }

    // MARK: TC-18

    func test_GH93_TC18_지우기로로그아웃하면_로컬위시와알림사진을지우고_비회원이된다() {
        // Given
        let wishes = [makeWish(id: "w1"), makeWish(id: "w2")]
        wishRepository.eraseAllLocalWishesResult = .success(wishes)
        let sut = makeSut(signedIn: true)
        sut.send(.tapLogout)

        // When
        sut.send(.selectLogout(.erase))

        // Then
        XCTAssertEqual(wishRepository.eraseAllLocalWishesCallCount, 1)
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), ["w1", "w2"])
        XCTAssertEqual(photoStorage.deletePhotosCalledWishIds, ["w1", "w2"])
        XCTAssertNil(sut.state.account)
        sut.send(.routeHandled)
        XCTAssertEqual(sut.route, .toast(Strings.Account.Toast.erased))
    }

    // MARK: TC-19

    func test_GH93_TC19_계정삭제는_재인증후_서버데이터_토큰해지_계정삭제순으로하고_남길지묻는다() {
        // Given
        let sut = makeSut(signedIn: true)
        sut.send(.tapDeleteAccount)
        XCTAssertEqual(sut.state.dialog, .deleteConfirm)
        sut.send(.confirmDeleteAccount)
        XCTAssertEqual(sut.route, .requestAppleAuthorization(nonce: "hashed"))
        sut.send(.routeHandled)

        // When
        sut.send(.appleAuthorized(credential))

        // Then
        waitUntil { sut.state.dialog == .afterDelete }
        XCTAssertEqual(callLog.calls, ["reauthenticate", "eraseServerData:uid-1", "revoke:code-1", "deleteUser"])
        XCTAssertNil(sut.state.account)
        XCTAssertEqual(sut.route, .popAccount)
        XCTAssertEqual(customEvents(.accountDelete).count, 1)

        // 삭제 뒤 선택은 닫을 수 없다
        sut.send(.dismissDialog)
        XCTAssertEqual(sut.state.dialog, .afterDelete)
        sut.send(.selectAfterDelete(.keep))
        XCTAssertNil(sut.state.dialog)
        XCTAssertEqual(wishRepository.eraseAllLocalWishesCallCount, 0)
    }

    func test_GH93_TC19_계정삭제가실패하면_계정이남고_오류토스트() {
        // Given
        accountManager.deleteError = AccountError.failed("requires-recent-login")
        let sut = makeSut(signedIn: true)
        sut.send(.tapDeleteAccount)
        sut.send(.confirmDeleteAccount)
        sut.send(.routeHandled)

        // When
        sut.send(.appleAuthorized(credential))

        // Then
        waitUntil { sut.route == .toast(Strings.Account.Error.delete) }
        XCTAssertEqual(sut.state.account, member)
        XCTAssertNil(sut.state.dialog)
        XCTAssertTrue(customEvents(.accountDelete).isEmpty)
    }

    // MARK: TC-20

    func test_GH93_TC20_오프라인에서계정삭제를누르면_막고안내한다() {
        // Given
        network.isConnected = false
        let sut = makeSut(signedIn: true)

        // When
        sut.send(.tapDeleteAccount)

        // Then
        XCTAssertNil(sut.state.dialog)
        XCTAssertEqual(sut.route, .toast(Strings.Account.Toast.offlineDelete))
        XCTAssertTrue(callLog.calls.isEmpty)
    }

    // MARK: TC-21

    func test_GH93_TC21_sync_enabled가꺼져있으면_계정카드를숨긴다() {
        XCTAssertFalse(makeSut(isSyncEnabled: false).state.isAvailable)
        XCTAssertTrue(makeSut(isSyncEnabled: true).state.isAvailable)
    }
}
