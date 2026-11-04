import Foundation
import Observation

extension AccountViewModel {
    enum Action: Equatable {
        /// 마이 탭이 보일 때. 로그인 상태·`sync_enabled`를 다시 읽는다
        case onAppear
        /// 비회원 카드 "Apple로 계속하기"
        case tapSignIn
        /// View 가 Apple 로그인 시트에서 받은 값 (로그인·계정 삭제 재인증 공용)
        case appleAuthorized(AppleCredential)
        case appleAuthorizationFailed(isCanceled: Bool)
        /// 회원 카드 → 계정 화면
        case tapAccountCard
        case tapLogout
        case selectLogout(LocalDataChoice)
        case tapDeleteAccount
        case confirmDeleteAccount
        /// 계정 삭제가 끝난 뒤 이 기기 싶을 남길지 (취소 없음)
        case selectAfterDelete(LocalDataChoice)
        case dismissDialog
        case routeHandled
    }

    enum LocalDataChoice: String, Equatable {
        case keep
        case erase
    }

    enum Dialog: Equatable {
        case logout
        case deleteConfirm
        case afterDelete
    }

    struct State: Equatable {
        /// Remote Config `sync_enabled`. 꺼져 있으면 계정 카드를 숨긴다 (R-30)
        var isAvailable = false
        var account: Account?
        var isWorking = false
        var dialog: Dialog?
    }

    enum Route: Equatable {
        /// View 가 Apple 로그인 시트를 띄운다. 값은 요청에 넣을 nonce(SHA-256)
        case requestAppleAuthorization(nonce: String)
        case pushAccount
        case popAccount
        case toast(String)
    }

    struct Dependency {
        let accountManager: AccountManagerProtocol
        let remoteDataEraser: RemoteAccountDataEraser
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol
        let photoStorage: WishPhotoStorage
        let network: NetworkStatusProviding
        let remoteConfigRepository: RemoteConfigRepository
        let logManager: LogManagerProtocol

        init(
            accountManager: AccountManagerProtocol = AccountManager.shared,
            remoteDataEraser: RemoteAccountDataEraser = NoRemoteAccountData(),
            wishRepository: WishRepository = WishRepositoryImpl(),
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            photoStorage: WishPhotoStorage = WishPhotoStorageImpl.shared,
            network: NetworkStatusProviding = NetworkMonitor.shared,
            remoteConfigRepository: RemoteConfigRepository = RemoteConfigRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.accountManager = accountManager
            self.remoteDataEraser = remoteDataEraser
            self.wishRepository = wishRepository
            self.notificationManager = notificationManager
            self.photoStorage = photoStorage
            self.network = network
            self.remoteConfigRepository = remoteConfigRepository
            self.logManager = logManager
        }
    }
}

/// 마이 탭 계정 카드와 계정 화면 (GH-93 R-24 ~ R-30). 두 화면이 같은 인스턴스를 쓴다
@Observable
final class AccountViewModel {
    /// 로그아웃 확인의 선택지 순서. 첫 번째가 기본 선택이다 (결정 6)
    static let logoutChoices: [LocalDataChoice] = [.keep, .erase]

    let screenName: ScreenName = .account
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency
    private var pendingAuthorization: (purpose: AuthorizationPurpose, nonce: AppleSignInNonce)?
    /// 계정 화면을 닫는 route 다음에 보여 줄 토스트. route 는 하나씩 처리되므로 닫은 뒤 이어서 낸다
    private var pendingToast: String?

    private enum AuthorizationPurpose {
        case signIn
        case deleteAccount
    }

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            state.isAvailable = dependency.remoteConfigRepository.fetchSyncEnabled()
            state.account = dependency.accountManager.currentAccount

        case .tapSignIn:
            sendClickLog(screen: .settings, objectId: .accountSignIn)
            guard !state.isWorking else { return }
            requestAuthorization(for: .signIn)

        case .appleAuthorized(let credential):
            guard let pending = pendingAuthorization else { return }
            pendingAuthorization = nil
            switch pending.purpose {
            case .signIn:
                signIn(credential: credential, nonce: pending.nonce)
            case .deleteAccount:
                deleteAccount(credential: credential, nonce: pending.nonce)
            }

        case .appleAuthorizationFailed(let isCanceled):
            pendingAuthorization = nil
            state.isWorking = false
            // 사용자가 시트를 닫은 건 오류가 아니다 (TC-15)
            if !isCanceled {
                route = .toast(Strings.Account.Error.signIn)
            }

        case .tapAccountCard:
            sendClickLog(screen: .settings, objectId: .accountCard)
            route = .pushAccount

        case .tapLogout:
            sendClickLog(screen: screenName, objectId: .logout)
            state.dialog = .logout

        case .selectLogout(let choice):
            state.dialog = nil
            signOut(choice: choice)

        case .tapDeleteAccount:
            sendClickLog(screen: screenName, objectId: .deleteAccount)
            guard dependency.network.isConnected else {
                route = .toast(Strings.Account.Toast.offlineDelete)
                return
            }
            state.dialog = .deleteConfirm

        case .confirmDeleteAccount:
            state.dialog = nil
            requestAuthorization(for: .deleteAccount)

        case .selectAfterDelete(let choice):
            state.dialog = nil
            if choice == .erase {
                eraseLocalWishes()
                route = .toast(Strings.Account.Toast.erased)
            }

        case .dismissDialog:
            // 계정 삭제 뒤 선택은 닫을 수 없다 (R-29)
            if state.dialog != .afterDelete {
                state.dialog = nil
            }

        case .routeHandled:
            route = pendingToast.map(Route.toast)
            pendingToast = nil
        }
    }

    // MARK: - Private

    private func requestAuthorization(for purpose: AuthorizationPurpose) {
        let nonce = dependency.accountManager.makeNonce()
        pendingAuthorization = (purpose, nonce)
        state.isWorking = true
        route = .requestAppleAuthorization(nonce: nonce.sha256)
    }

    private func signIn(credential: AppleCredential, nonce: AppleSignInNonce) {
        let accountManager = dependency.accountManager
        Task { @MainActor [weak self] in
            do {
                let account = try await accountManager.signIn(with: credential, nonce: nonce)
                guard let self else { return }
                state.account = account
                state.isWorking = false
                dependency.logManager.sendEvent(event: CustomEvent(screen: .settings, name: .accountSignIn))
                route = .toast(Strings.Account.Toast.signedIn)
            } catch {
                guard let self else { return }
                state.isWorking = false
                route = .toast(Strings.Account.Error.signIn)
            }
        }
    }

    private func signOut(choice: LocalDataChoice) {
        do {
            try dependency.accountManager.signOut()
        } catch {
            route = .toast(Strings.Account.Error.signOut)
            return
        }
        if choice == .erase {
            eraseLocalWishes()
        }
        state.account = nil
        dependency.logManager.sendEvent(event: CustomEvent(
            screen: screenName,
            name: .accountSignOut,
            extraParameters: [.type: choice.rawValue]
        ))
        route = .popAccount
        pendingToast = choice == .erase ? Strings.Account.Toast.erased : Strings.Account.Toast.signedOut
    }

    /// 서버 데이터 → Apple 토큰 → Auth 사용자 순서로 지운다 (설계 §8). 중간에 실패하면 계정은 남아 다시 시도할 수 있다
    private func deleteAccount(credential: AppleCredential, nonce: AppleSignInNonce) {
        guard let uid = state.account?.uid, let authorizationCode = credential.authorizationCode else {
            state.isWorking = false
            route = .toast(Strings.Account.Error.delete)
            return
        }
        let accountManager = dependency.accountManager
        let remoteDataEraser = dependency.remoteDataEraser
        Task { @MainActor [weak self] in
            do {
                try await accountManager.reauthenticate(with: credential, nonce: nonce)
                try await remoteDataEraser.eraseAll(uid: uid)
                try await accountManager.revokeAppleToken(authorizationCode: authorizationCode)
                try await accountManager.deleteUser()
                guard let self else { return }
                state.isWorking = false
                state.account = nil
                state.dialog = .afterDelete
                dependency.logManager.sendEvent(event: CustomEvent(screen: screenName, name: .accountDelete))
                route = .popAccount
                pendingToast = Strings.Account.Toast.deleted
            } catch {
                guard let self else { return }
                state.isWorking = false
                route = .toast(Strings.Account.Error.delete)
            }
        }
    }

    private func eraseLocalWishes() {
        guard case .success(let wishes) = dependency.wishRepository.eraseAllLocalWishes() else { return }
        for wish in wishes {
            dependency.notificationManager.cancelNotifications(wish: wish)
            dependency.photoStorage.deletePhotos(wishId: wish.id)
        }
    }

    private func sendClickLog(screen: ScreenName, objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(screen: screen, objectType: .button, objectId: objectId))
    }
}
