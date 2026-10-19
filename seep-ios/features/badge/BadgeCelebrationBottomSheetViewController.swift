import UIKit
import Combine

import CombineCocoa
import PanModal
import SnapKit

/// 새 배지 축하 바텀시트 (GH-35 R-6). 여러 개를 한 번에 얻으면 카드를 세로로 나열한다.
final class BadgeCelebrationBottomSheetViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let bottomInset: CGFloat = 8
        static let cardSpacing: CGFloat = 10
        /// 카드가 이보다 높아지면 카드 영역만 스크롤한다 (카드 약 3장 반)
        static let maxCardsHeight: CGFloat = 400
        /// 레이아웃 전 첫 표시용 높이. 실제 높이는 viewDidLayoutSubviews 에서 콘텐츠에 맞춘다
        static let estimatedContentHeight: CGFloat = 360
    }

    private let viewModel: BadgeCelebrationViewModel
    private var contentHeight: CGFloat = Layout.estimatedContentHeight

    private let indicatorView = BottomSheetIndicator()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let cardsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let cardsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.cardSpacing
        return stackView
    }()

    private let confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Badge.Celebration.confirm, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .appleExtraBold(size: 17)
        button.backgroundColor = .tennisGreen
        button.layer.cornerRadius = 25
        return button
    }()

    private let viewBadgesButton: BadgeLinkButton = {
        let button = BadgeLinkButton()
        button.setTitle(Strings.Badge.Celebration.viewBadges)
        return button
    }()

    init(viewModel: BadgeCelebrationViewModel) {
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
        viewModel.input.viewDidLoad.send(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let fittedHeight = ceil(viewBadgesButton.frame.maxY + Layout.bottomInset)
        guard fittedHeight > 0, abs(fittedHeight - contentHeight) > 0.5 else { return }
        contentHeight = fittedHeight
        // 높이만 바꾸면 시트 위치는 그대로라 콘텐츠가 화면 아래로 잘린다. 새 높이의 shortForm 위치로 옮긴다
        panModalSetNeedsLayoutUpdate()
        panModalTransition(to: .shortForm)
    }

    private func setupUI() {
        view.backgroundColor = .white
        cardsScrollView.addSubview(cardsStackView)
        view.addSubViews([indicatorView, titleLabel, cardsScrollView, confirmButton, viewBadgesButton])

        indicatorView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(indicatorView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset + 2)
        }

        cardsScrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.height.equalTo(cardsStackView).priority(.high)
            $0.height.lessThanOrEqualTo(Layout.maxCardsHeight)
        }

        cardsStackView.snp.makeConstraints {
            $0.edges.equalTo(cardsScrollView.contentLayoutGuide)
            $0.width.equalTo(cardsScrollView.frameLayoutGuide)
        }

        confirmButton.snp.makeConstraints {
            $0.top.equalTo(cardsScrollView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.height.equalTo(50)
        }

        viewBadgesButton.snp.makeConstraints {
            $0.top.equalTo(confirmButton.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(44)
        }
    }

    private func bindContent() {
        let text = Strings.Badge.Celebration.titleFormat(viewModel.output.finishedCount)
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleLight(size: 22) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: (text as NSString).range(of: Strings.Badge.Celebration.titleBold, options: .backwards)
        )
        titleLabel.attributedText = attributedText

        viewModel.output.badges.forEach {
            cardsStackView.addArrangedSubview(BadgeCelebrationCardView(badge: $0))
        }
        cardsScrollView.isScrollEnabled = viewModel.output.badges.count > 3
    }

    private func bind() {
        confirmButton.tapPublisher
            .subscribe(viewModel.input.didTapConfirm)
            .store(in: &cancellables)

        viewBadgesButton.controlEventPublisher(for: .touchUpInside)
            .subscribe(viewModel.input.didTapViewBadges)
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: BadgeCelebrationBottomSheetViewController, route: BadgeCelebrationViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Route
extension BadgeCelebrationBottomSheetViewController {
    private func handleRoute(_ route: BadgeCelebrationViewModel.Route) {
        switch route {
        case .dismiss:
            dismiss(animated: true)
        }
    }
}

extension BadgeCelebrationBottomSheetViewController: PanModalPresentable {
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
        return 20
    }
}

/// 축하 시트의 배지 카드: `gray2` 카드 · 메달 72 + 이름 + "조건 · 얻은 날"
private final class BadgeCelebrationCardView: UIView {
    private let medalView = BadgeMedalView(diameter: 72, fillColor: .gray1)

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 16)
        label.textColor = .gray5
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.numberOfLines = 0
        return label
    }()

    init(badge: Badge) {
        super.init(frame: .zero)
        setupUI()

        medalView.bind(type: badge.type, isEarned: true)
        nameLabel.text = badge.type.name
        descriptionLabel.text = Strings.Badge.Celebration.cardDescriptionFormat(
            badge.type.conditionText,
            badge.earnedDateText ?? ""
        )
        isAccessibilityElement = true
        accessibilityLabel = [nameLabel.text, descriptionLabel.text].compactMap { $0 }.joined(separator: ", ")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .gray2
        layer.cornerRadius = 12
        let textStackView = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        addSubViews([medalView, textStackView])

        medalView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview().inset(20)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(medalView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
    }
}
