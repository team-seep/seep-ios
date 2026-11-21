import CryptoKit
import Foundation

import FirebaseAuth

/// 로그인·로그아웃·계정 삭제 (GH-93 R-26 ~ R-29). Firebase Auth 는 여기서만 쓴다(R11)
protocol AccountManagerProtocol: AnyObject {
    var currentAccount: Account? { get }

    /// Apple 로그인 요청마다 새로 만든다
    func makeNonce() -> AppleSignInNonce

    /// Apple 로그인 결과로 Firebase 에 로그인한다. 처음 쓰는 Apple ID 면 그대로 가입이다
    func signIn(with credential: AppleCredential, nonce: AppleSignInNonce) async throws -> Account

    func signOut() throws

    /// 계정 삭제 전 재인증 (최근 로그인이 아니면 Firebase 가 삭제를 막는다)
    func reauthenticate(with credential: AppleCredential, nonce: AppleSignInNonce) async throws

    /// Apple 토큰 해지 (App Store 가이드라인 5.1.1(v))
    func revokeAppleToken(authorizationCode: String) async throws

    /// Firebase Auth 사용자를 지운다
    func deleteUser() async throws
}

final class AccountManager: AccountManagerProtocol {
    static let shared = AccountManager()

    var currentAccount: Account? {
        Auth.auth().currentUser.map(Self.account(of:))
    }

    func makeNonce() -> AppleSignInNonce {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        let raw = String((0..<32).map { _ in charset.randomElement(using: &generator) ?? "0" })
        let hash = SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
        return AppleSignInNonce(raw: raw, sha256: hash)
    }

    func signIn(with credential: AppleCredential, nonce: AppleSignInNonce) async throws -> Account {
        let result = try await Auth.auth().signIn(with: firebaseCredential(credential, nonce: nonce))
        return Self.account(of: result.user)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func reauthenticate(with credential: AppleCredential, nonce: AppleSignInNonce) async throws {
        guard let user = Auth.auth().currentUser else { throw AccountError.notSignedIn }
        // 다른 Apple ID 로 재인증하면 Firebase 가 userMismatch 로 막는다
        _ = try await user.reauthenticate(with: firebaseCredential(credential, nonce: nonce))
    }

    func revokeAppleToken(authorizationCode: String) async throws {
        try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
    }

    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser else { throw AccountError.notSignedIn }
        try await user.delete()
    }

    private func firebaseCredential(_ credential: AppleCredential, nonce: AppleSignInNonce) -> AuthCredential {
        OAuthProvider.appleCredential(
            withIDToken: credential.idToken,
            rawNonce: nonce.raw,
            fullName: credential.fullName
        )
    }

    private static func account(of user: User) -> Account {
        Account(uid: user.uid, email: user.email, createdAt: user.metadata.creationDate)
    }
}
