import SwiftUI
import WidgetKit

/// 스플래시 → 메인 전환, 토스트·앱 잠금 오버레이, 위젯 링크·생명주기를 받는 루트 (GH-64 A-1, A-8)
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(AppLockOverlayViewModel.self) private var appLock
    @Environment(\.scenePhase) private var scenePhase

    @State private var isSplashFinished = false
    /// 설정 "화면 모드". `Preference.appearance`가 같은 키에 쓴다 (GH-85 R-3)
    @AppStorage(AppAppearance.storageKey) private var appearanceRawValue = AppAppearance.system.rawValue

    var logManager: LogManagerProtocol = LogManager.shared

    var body: some View {
        ZStack {
            if isSplashFinished {
                MainTabView()
                    .transition(.opacity)
                    .onAppear(perform: mainDidAppear)
            } else {
                SplashScreen {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSplashFinished = true
                    }
                }
            }
        }
        .toastOverlay(toastCenter)
        .appLockOverlay()
        .preferredColorScheme(AppAppearance(rawValue: appearanceRawValue)?.colorScheme)
        .onOpenURL { url in
            log(router.open(url: url))
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                appLock.send(.phaseChanged(.active))
            case .inactive:
                appLock.send(.phaseChanged(.inactive))
            case .background:
                WidgetCenter.shared.reloadAllTimelines()
                appLock.send(.phaseChanged(.background))
            @unknown default:
                break
            }
        }
    }

    private func mainDidAppear() {
        // 콜드 스타트 잠금은 스플래시 다음, 메인이 뜨는 순간에 덮는다 (GH-46 R-5)
        appLock.send(.mainDidAppear)
        log(router.mainDidAppear())
    }

    /// 위젯은 GA 를 직접 보내지 못해, 링크로 화면을 옮겼을 때 앱이 클릭 로그를 남긴다 (GH-47, GH-49)
    private func log(_ deepLink: WidgetDeepLink?) {
        guard let deepLink else { return }
        if let event = deepLink.source?.clickEvent {
            logManager.sendEvent(event: event)
        }
        if let event = deepLink.writeIntentClickEvent {
            logManager.sendEvent(event: event)
        }
    }
}
