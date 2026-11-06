import AuthenticationServices
import SwiftUI

/// Apple 로그인 시트 (GH-93 R-26). 시트는 화면이 띄워야 해서 View 쪽에 두고, 결과는 `AppleCredential`로만 ViewModel 에 넘긴다
enum AppleAuthorization {
    enum Outcome {
        case authorized(AppleCredential)
        case failed(isCanceled: Bool)
    }

    @MainActor
    static func perform(nonce: String, with controller: AuthorizationController) async -> Outcome {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = nonce
        do {
            let result = try await controller.performRequest(request)
            guard case .appleID(let appleID) = result,
                  let tokenData = appleID.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                return .failed(isCanceled: false)
            }
            return .authorized(AppleCredential(
                idToken: idToken,
                authorizationCode: appleID.authorizationCode.flatMap { String(data: $0, encoding: .utf8) },
                fullName: appleID.fullName
            ))
        } catch let error as ASAuthorizationError where error.code == .canceled {
            return .failed(isCanceled: true)
        } catch {
            return .failed(isCanceled: false)
        }
    }
}
