import SwiftUI

/// 앱 진입점 (GH-64 A-1). Firebase·Realm·알림 델리게이트는 `AppDelegate`가 맡는다
@main
struct SeepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment.router)
                .environment(environment.toastCenter)
                .environment(environment.appLock)
        }
    }
}
