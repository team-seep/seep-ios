import Foundation

@testable import seep_ios_dev

final class MockAuthenticationManager: AuthenticationManagerProtocol {
    var isAuthenticating = false
    var canAuthenticateResult = true
    var biometryResult: AppLockBiometry = .faceID
    var authenticateResult = true
    private(set) var authenticateCallCount = 0

    func canAuthenticate() -> Bool {
        return canAuthenticateResult
    }

    func biometry() -> AppLockBiometry {
        return biometryResult
    }

    /// 실제 구현은 메인 스레드로 돌려주지만, 목은 동기로 바로 부른다.
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        authenticateCallCount += 1
        completion(authenticateResult)
    }
}
