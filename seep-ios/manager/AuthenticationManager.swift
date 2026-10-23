import Foundation
import LocalAuthentication

/// 앱 잠금에 쓰는 인증 수단. 문구의 "{생체 종류}" 자리에 들어간다 (GH-46 R-2)
enum AppLockBiometry: Equatable {
    case faceID
    case touchID
    /// 생체 인증이 없거나 등록되지 않은 기기. 기기 암호로 인증한다
    case passcode

    var name: String {
        switch self {
        case .faceID:
            return Strings.AppLock.Biometry.faceId
        case .touchID:
            return Strings.AppLock.Biometry.touchId
        case .passcode:
            return Strings.AppLock.Biometry.passcode
        }
    }
}

/// `LAContext` 래퍼 (GH-46 R-9). ViewModel 은 이 protocol 로만 인증한다
protocol AuthenticationManagerProtocol: AnyObject {
    /// 앱이 띄운 인증 창이 떠 있는 동안 true. 인증 창 때문에 앱이 비활성화될 때 잠금 덮개를 씌우지 않으려고 쓴다 (R-7)
    var isAuthenticating: Bool { get }

    /// 기기 암호(또는 생체)로 인증할 수 있는지. 기기 암호가 없으면 false (R-4)
    func canAuthenticate() -> Bool

    func biometry() -> AppLockBiometry

    /// 생체 인증, 실패하면 기기 암호로 넘어가는 인증. completion 은 메인 스레드에서 부른다
    func authenticate(reason: String, completion: @escaping (Bool) -> Void)
}

final class AuthenticationManager: AuthenticationManagerProtocol {
    static let shared = AuthenticationManager()

    private(set) var isAuthenticating = false
    /// 인증하는 동안 컨텍스트를 붙잡아 둔다. 먼저 해제되면 인증 창이 취소될 수 있다
    private var evaluatingContext: LAContext?

    func canAuthenticate() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func biometry() -> AppLockBiometry {
        let context = LAContext()
        var error: NSError?
        // biometryType 은 canEvaluatePolicy 를 부른 뒤에야 채워진다.
        // 하드웨어만 있고 등록하지 않았으면 실제로는 기기 암호를 묻게 되므로 기기 암호로 본다
        let canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let isLockedOut = (error as? LAError)?.code == .biometryLockout
        guard canUseBiometrics || isLockedOut else { return .passcode }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .passcode
        }
    }

    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        evaluatingContext = context
        isAuthenticating = true
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] isSuccess, _ in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                self?.evaluatingContext = nil
                completion(isSuccess)
            }
        }
    }
}
