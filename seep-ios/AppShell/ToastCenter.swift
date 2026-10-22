import SwiftUI
import Observation

/// 앱 전체 토스트. 루트(`RootView`)에 `.toastOverlay(_:)`로 한 번 붙이고, 어디서든 `show`로 띄운다 (GH-64 A-7).
/// 새 토스트가 오면 이전 것을 바로 바꾼다
@MainActor
@Observable
final class ToastCenter {
    static let defaultDuration: Duration = .seconds(2)

    private(set) var message: String?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, duration: Duration = ToastCenter.defaultDuration) {
        dismissTask?.cancel()
        self.message = message
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        message = nil
    }
}

extension View {
    /// 화면 아래 토스트. 바탕 gray5·라운드 8·흰 Medium 14 (디자인 시스템 Toast)
    func toastOverlay(_ center: ToastCenter) -> some View {
        overlay(alignment: .bottom) {
            if let message = center.message {
                Text(verbatim: message)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray5, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 100)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .onTapGesture { center.dismiss() }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: center.message)
    }
}
