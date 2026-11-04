import Foundation

/// 로그인한 계정 (GH-93 R-24, R-27). Firebase 타입을 화면에 넘기지 않으려고 값만 옮겨 담는다(R11)
struct Account: Equatable {
    let uid: String
    /// Apple 에서 이메일 가리기를 고르면 `…@privaterelay.appleid.com`
    let email: String?
    let createdAt: Date?
}

/// Apple 로그인 요청에 쓰는 nonce. 원문은 Firebase 에, SHA-256 값은 Apple 요청에 넣는다
struct AppleSignInNonce: Equatable {
    let raw: String
    let sha256: String
}

/// Apple 로그인 결과에서 Firebase 로그인·토큰 해지에 필요한 값만 옮긴 것
struct AppleCredential: Equatable {
    let idToken: String
    let authorizationCode: String?
    let fullName: PersonNameComponents?
}

enum AccountError: Error, Equatable {
    case notSignedIn
    /// Apple 응답에 토큰·인증 코드가 없다
    case missingAppleToken
    case failed(String)
}
