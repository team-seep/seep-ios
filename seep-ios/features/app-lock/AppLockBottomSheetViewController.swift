import UIKit
import Combine

import CombineCocoa
import PanModal
import SnapKit

/// 잠금 켜기·끄기 바텀시트 (GH-46 R-2). 디자인 After 1 / After 3
final class AppLockBottomSheetViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let bottomInset: CGFloat = 8
        /// 레이아웃 전 첫 표시용 높이. 실제 높이는 viewDidLayoutSubviews 에서 콘텐츠에 맞춘다
        static let estimatedContentHeight: CGFloat = 280
    }

    private let viewModel: AppLockBottomSheetViewModel
    private var contentHeight: CGFloat = Layout.estimatedContentHeight

    private let indicatorView = BottomSheetIndicator()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let confirmButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .appleExtraBold(size: 17)
        button.layer.cornerRadius = 25
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.gray4, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        return button
    }()

    init(viewModel: AppLockBottomSheetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindContent()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let fittedHeight = ceil(closeButton.frame.maxY + Layout.bottomInset)
        guard fittedHeight > 0, abs(fittedHeight - contentHeight) > 0.5 else { return }
        contentHeight = fittedHeight
        panModalSetNeedsLayoutUpdate()
        panModalTransition(to: .shortForm)
    }

    private func setupUI() {
        view.backgroundColor = .gray1
        view.addSubViews([indicatorView, titleLabel, descriptionLabel, confirmButton, closeButton])

        indicatorView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(indicatorView.snp.bottom).offset(22)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset + 2)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(titleLabel)
        }

        confirmButton.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.height.equalTo(50)
        }

        closeButton.snp.makeConstraints {
            $0.top.equalTo(confirmButton.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(44)
        }
    }

    private func bindContent() {
        let output = viewModel.output
        let title = NSMutableAttributedString(
            string: output.title,
            attributes: [.font: UIFont.appleLight(size: 22) as Any, .foregroundColor: UIColor.gray5]
        )
        title.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: (output.title as NSString).range(of: output.titleBold, options: .backwards)
        )
        titleLabel.attributedText = title

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 20
        descriptionLabel.attributedText = NSAttributedString(
            string: output.description,
            attributes: [
                .font: UIFont.appleRegular(size: 14) as Any,
                .foregroundColor: UIColor.gray4,
                .paragraphStyle: paragraphStyle
            ]
        )

        confirmButton.setTitle(output.confirmButtonTitle, for: .normal)
        // 끄기는 되돌리는 동작이라 강조색을 쓰지 않는다 (디자인 After 3)
        confirmButton.backgroundColor = output.isEnabled ? .gray2 : .tennisGreen
        confirmButton.setTitleColor(output.isEnabled ? .gray5 : .gray1, for: .normal)
        closeButton.setTitle(output.closeButtonTitle, for: .normal)
    }

    private func bind() {
        confirmButton.tapPublisher
            .subscribe(viewModel.input.didTapConfirm)
            .store(in: &cancellables)

        closeButton.tapPublisher
            .subscribe(viewModel.input.didTapClose)
            .store(in: &cancellables)

        viewModel.output.toast
            .main
            .sink { (message: String) in
                ToastManager.shared.show(message: message)
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: AppLockBottomSheetViewController, route: AppLockBottomSheetViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Route
extension AppLockBottomSheetViewController {
    private func handleRoute(_ route: AppLockBottomSheetViewModel.Route) {
        switch route {
        case .dismiss:
            dismiss(animated: true)
        }
    }
}

extension AppLockBottomSheetViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeight(contentHeight)
    }

    var longFormHeight: PanModalHeight {
        shortFormHeight
    }

    var showDragIndicator: Bool {
        return false
    }

    var cornerRadius: CGFloat {
        return 16
    }
}
