import SwiftUI
import Observation

/// 앱 전체 토스트. 루트(`RootView`)에 `.toastOverlay(_:)`로 한 번 붙이고, 어디서든 `show`로 띄운다 (GH-64 A-7).
/// 새 토스트가 오면 이전 것을 바로 바꾼다. 버튼 하나("되돌리기" 등)를 붙일 수 있다 (GH-143 R-3).
/// 버튼 있는 토스트는 버튼 없는 토스트에 밀리지 않는다: 같이 오면(예: 첫 저금이 목표 달성 + 자동 시작) 버튼 토스트를 먼저 보이고 끝나면 나머지를 띄운다
@MainActor
@Observable
final class ToastCenter {
    static let defaultDuration: Duration = .seconds(2)
    /// 버튼이 있는 토스트는 누를 시간을 주려고 더 오래 둔다
    static let actionDuration: Duration = .seconds(4)

    private(set) var message: String?
    /// 토스트 오른쪽 버튼 제목. nil 이면 버튼 없음
    private(set) var actionTitle: String?
    private var action: (() -> Void)?
    /// 버튼 토스트가 끝나면 이어서 띄울 버튼 없는 토스트
    private var pending: (message: String, duration: Duration)?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, duration: Duration = ToastCenter.defaultDuration) {
        if actionTitle != nil {
            pending = (message, duration)
            return
        }
        present(message, actionTitle: nil, action: nil, duration: duration)
    }

    /// 버튼이 있는 토스트. 버튼을 누르면 토스트를 닫고 `action`을 부른다
    func show(_ message: String, actionTitle: String, duration: Duration = ToastCenter.actionDuration, action: @escaping () -> Void) {
        // 방금 뜬 버튼 없는 토스트는 버튼 토스트 뒤로 미룬다
        if let message = self.message, self.actionTitle == nil {
            pending = (message, Self.defaultDuration)
        }
        present(message, actionTitle: actionTitle, action: action, duration: duration)
    }

    func performAction() {
        let action = self.action
        dismiss()
        action?()
    }

    func dismiss() {
        dismissTask?.cancel()
        message = nil
        actionTitle = nil
        action = nil
        if let pending {
            self.pending = nil
            present(pending.message, actionTitle: nil, action: nil, duration: pending.duration)
        }
    }

    private func present(_ message: String, actionTitle: String?, action: (() -> Void)?, duration: Duration) {
        dismissTask?.cancel()
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }
}

extension View {
    /// 화면 아래 토스트. 바탕 gray5·라운드 8·흰 Medium 14 (디자인 시스템 Toast).
    /// 버튼이 있으면 오른쪽에 Bold 13 `gray3` 글자 버튼(터치 영역 높이 44)
    func toastOverlay(_ center: ToastCenter) -> some View {
        overlay(alignment: .bottom) {
            if let message = center.message {
                HStack(spacing: 12) {
                    Text(verbatim: message)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray1)
                        .padding(.vertical, 12)
                        .accessibilityAddTraits(.isStaticText)
                    if let actionTitle = center.actionTitle {
                        Button {
                            center.performAction()
                        } label: {
                            Text(verbatim: actionTitle)
                                .font(.appleBold(size: 13))
                                .foregroundStyle(Color.gray3)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .background(Color.gray5, in: RoundedRectangle(cornerRadius: 8))
                // 버튼 밖 토스트 어디를 눌러도 닫힌다
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture { center.dismiss() }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: center.message)
    }
}
