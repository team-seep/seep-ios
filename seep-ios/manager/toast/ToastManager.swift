import UIKit

protocol ToastProtocol: AnyObject {
    func show(message: String)
}

final class ToastManager: ToastProtocol {
    enum Layout {
        static let horizontalMargin: CGFloat = 20
        static let topMargin: CGFloat = 14
        static let height: CGFloat = 58
    }

    static let shared = ToastManager()

    private let toastView: ToastView = {
        let view = ToastView(frame: .zero)
        view.actionButton.isHidden = true
        return view
    }()

    /// 토스트가 최종적으로 놓일 위치. 상·좌·우 safe area 안쪽에 둔다.
    /// 듀오 바깥 화면처럼 오른쪽에 센서·상태 표시 영역(safe area 오른쪽 inset)이 있어도 겹치지 않게
    /// 화면 폭이 아니라 띄울 window의 bounds와 safe area로 계산한다.
    static func frame(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGRect {
        let x = safeAreaInsets.left + Layout.horizontalMargin
        let width = bounds.width - safeAreaInsets.left - safeAreaInsets.right - Layout.horizontalMargin * 2
        return CGRect(
            x: x,
            y: safeAreaInsets.top + Layout.topMargin,
            width: max(width, 0),
            height: Layout.height
        )
    }

    func show(message: String) {
        guard let window = keyWindow() else { return }

        let frame = Self.frame(in: window.bounds, safeAreaInsets: window.safeAreaInsets)
        toastView.transform = .identity
        toastView.frame = frame
        // 화면 위쪽 밖에서 내려오도록 시작 위치를 최종 위치의 위로 둔다
        toastView.transform = .init(translationX: 0, y: -frame.maxY)
        window.addSubview(toastView)
        toastView.messageLabel.text = message

        UIView.transition(
            with: toastView,
            duration: 0.3,
            options: .curveEaseInOut
        ) { [weak self] in
            self?.toastView.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.hide()
            }
        }
    }

    private func hide() {
        UIView.transition(
            with: toastView,
            duration: 0.3,
            options: .curveEaseInOut
        ) { [weak self] in
            guard let self else { return }
            self.toastView.transform = .init(translationX: 0, y: -self.toastView.frame.maxY)
        } completion: { [weak self] isCompleteRemove in
            if isCompleteRemove {
                self?.toastView.removeFromSuperview()
            }
        }
    }

    private func keyWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first
    }
}
