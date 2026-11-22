import Foundation

import FirebaseAppCheck
import FirebaseCore

/// App Check 공급자 종류 (GH-145 R-10)
enum AppCheckProviderKind: Equatable {
    /// 실기기: Apple App Attest로 정품 앱임을 증명한다
    case appAttest
    /// 시뮬레이터: App Attest가 없어 콘솔에 등록한 디버그 토큰을 쓴다
    case debug

    static func resolve(isSimulator: Bool) -> AppCheckProviderKind {
        isSimulator ? .debug : .appAttest
    }

    static var current: AppCheckProviderKind {
        #if targetEnvironment(simulator)
        resolve(isSimulator: true)
        #else
        resolve(isSimulator: false)
        #endif
    }
}

/// Firestore·Storage 요청에 App Check 토큰을 붙인다. 콘솔에서 강제(enforce)하기 전에는 토큰이 없어도 요청이 통과하므로
/// 증명에 실패해도 비회원 기능이나 동기화가 멈추지 않는다 (R-13)
enum AppCheckSetup {
    /// `FirebaseApp.configure()`보다 먼저 불러야 한다
    static func configure() {
        AppCheck.setAppCheckProviderFactory(SeepAppCheckProviderFactory())
    }
}

private final class SeepAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        switch AppCheckProviderKind.current {
        case .appAttest:
            return AppAttestProvider(app: app)
        case .debug:
            return AppCheckDebugProvider(app: app)
        }
    }
}
