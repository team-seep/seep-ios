import SwiftUI

/// 화면 페이지뷰를 처음 나타날 때 한 번만 보낸다. `BaseViewController.viewDidLoad`의 SwiftUI판 (GH-64 A-9).
/// 탭 전환·push 후 돌아와 다시 나타나도 보내지 않는다
final class ScreenTracker {
    private(set) var didSend = false

    func trackIfNeeded(screen: ScreenName, logManager: LogManagerProtocol) {
        guard !didSend else { return }
        didSend = true
        logManager.sendPageView(screen: screen, type: ScreenTracker.self)
    }
}

extension View {
    func trackScreen(_ screen: ScreenName, logManager: LogManagerProtocol = LogManager.shared) -> some View {
        modifier(TrackScreenModifier(screen: screen, logManager: logManager))
    }
}

private struct TrackScreenModifier: ViewModifier {
    let screen: ScreenName
    let logManager: LogManagerProtocol
    @State private var tracker = ScreenTracker()

    func body(content: Content) -> some View {
        content.onAppear {
            tracker.trackIfNeeded(screen: screen, logManager: logManager)
        }
    }
}
