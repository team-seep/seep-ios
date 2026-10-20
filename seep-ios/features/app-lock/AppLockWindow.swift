import UIKit
import Combine

/// 잠금 화면을 앱 전체(시트·알럿 포함) 위에 덮는 윈도우 (GH-46 R-5).
/// 아래 앱은 그대로 두고 덮기만 하므로, 잠긴 동안 들어온 위젯 링크도 아래에서 평소대로 처리되고 잠금이 풀리면 그 화면이 보인다 (R-8)
final class AppLockWindow: UIWindow {
    private enum Constant {
        static let fadeOutDuration: TimeInterval = 0.25
    }

    private weak var mainWindow: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    init(windowScene: UIWindowScene, mainWindow: UIWindow?, viewModel: AppLockViewModel) {
        self.mainWindow = mainWindow
        super.init(windowScene: windowScene)

        windowLevel = .alert + 1
        rootViewController = AppLockViewController(viewModel: viewModel)
        isHidden = true
        bind(viewModel: viewModel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bind(viewModel: AppLockViewModel) {
        viewModel.output.lockState
            .removeDuplicates()
            .main
            .withUnretained(self)
            .sink { (owner: AppLockWindow, lockState: AppLockViewModel.LockState) in
                switch lockState {
                case .covered, .locked:
                    owner.show()
                case .unlocked:
                    owner.hide()
                }
            }
            .store(in: &cancellables)
    }

    private func show() {
        // 전환기 스냅샷 전에 덮여야 하므로 애니메이션 없이 바로 보인다 (R-7)
        layer.removeAllAnimations()
        alpha = 1
        // 키 윈도우를 가져와 아래 화면의 키보드가 잠금 화면 위로 올라오지 않게 한다
        makeKeyAndVisible()
    }

    private func hide() {
        guard !isHidden else { return }
        mainWindow?.makeKey()
        UIView.animate(withDuration: Constant.fadeOutDuration, animations: { [weak self] in
            self?.alpha = 0
        }, completion: { [weak self] isFinished in
            // 사라지는 중에 다시 잠기면 show() 가 애니메이션을 끊는다. 그때는 숨기지 않는다
            guard isFinished else { return }
            self?.isHidden = true
        })
    }
}
