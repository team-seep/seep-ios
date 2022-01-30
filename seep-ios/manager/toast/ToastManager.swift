import UIKit

protocol ToastProtocol: AnyObject {
    func show(message: String)
}

final class ToastManager: ToastProtocol {
    static let shared = ToastManager()
    
    private let toastView = ToastView(
        frame: CGRect(
            x: 20,
            y: (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0) - 58,
            width: UIScreen.main.bounds.width - 40,
            height: 58
        )
    ).then {
        $0.actionButton.isHidden = true
        $0.messageLabel.text = "share_photo_success".localized
    }
    
    func show(message: String) {
        let window = UIApplication.shared.windows[0]
        
        window.addSubview(self.toastView)
        self.toastView.messageLabel.text = message
        
        UIView.transition(
            with: self.toastView,
            duration: 0.3,
            options: .curveEaseInOut
        ) { [weak self] in
            self?.toastView.transform = .init(translationX: 0, y: 14 + 58)
        } completion: { isComplete in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.hide()
            }
        }
    }
    
    private func hide() {
        UIView.transition(
            with: self.toastView,
            duration: 0.3,
            options: .curveEaseInOut
        ) { [weak self] in
            self?.toastView.transform = .identity
        } completion: { [weak self] isCompleteRemove in
            if isCompleteRemove {
                self?.toastView.removeFromSuperview()
            }
        }
    }
}
