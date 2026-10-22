import UIKit
import Combine

import CombineCocoa
import SnapKit

/// 배지 모아보기 화면 (GH-35 R-5).
final class BadgeCollectionViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let columnCount = 3
        static let spacing: CGFloat = 10
    }

    private let viewModel: LegacyBadgeCollectionViewModel

    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icChevronBack.image, for: .normal)
        button.accessibilityLabel = Strings.Badge.Collection.back
        return button
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        label.text = Strings.Badge.Collection.description
        return label
    }()

    private let gridStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.spacing
        return stackView
    }()

    private var cardViews: [BadgeCardView] = []

    init(viewModel: LegacyBadgeCollectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.input.viewWillAppear.send(())
    }

    private func setupUI() {
        view.backgroundColor = .gray2
        view.addSubViews([backButton, scrollView])
        scrollView.addSubview(contentView)
        contentView.addSubViews([titleLabel, descriptionLabel, gridStackView])
        setupGrid()

        backButton.snp.makeConstraints {
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            $0.size.equalTo(44)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.top.bottom.equalTo(scrollView.contentLayoutGuide)
            // 넓은 화면(듀오 안쪽)에서는 최대 폭 기둥으로 가운데 둔다
            $0.centerX.equalTo(scrollView.frameLayoutGuide)
            $0.width.lessThanOrEqualTo(WideScreenLayout.maxContentWidth)
            $0.width.equalTo(scrollView.frameLayoutGuide).priority(.high)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.trailing.equalToSuperview().inset(22)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(22)
        }

        gridStackView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.bottom.equalToSuperview().offset(-24)
        }
    }

    /// 배지 8종을 3열로 놓는다. 마지막 줄의 빈 칸은 투명 뷰로 채워 칸 폭을 맞춘다
    private func setupGrid() {
        cardViews = BadgeType.allCases.map { _ in BadgeCardView() }
        var index = 0
        while index < cardViews.count {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.spacing = Layout.spacing
            rowStackView.distribution = .fillEqually
            rowStackView.alignment = .top

            for column in 0..<Layout.columnCount {
                if let cardView = cardViews[safe: index + column] {
                    rowStackView.addArrangedSubview(cardView)
                } else {
                    rowStackView.addArrangedSubview(UIView())
                }
            }
            gridStackView.addArrangedSubview(rowStackView)
            index += Layout.columnCount
        }
    }

    private func bind() {
        backButton.tapPublisher
            .subscribe(viewModel.input.didTapBack)
            .store(in: &cancellables)

        viewModel.output.badges
            .main
            .withUnretained(self)
            .sink { (owner: BadgeCollectionViewController, badges: [Badge]) in
                zip(owner.cardViews, badges).forEach { cardView, badge in
                    cardView.bind(badge: badge)
                }
            }
            .store(in: &cancellables)

        viewModel.output.earnedCount
            .main
            .withUnretained(self)
            .sink { (owner: BadgeCollectionViewController, count: Int) in
                owner.setTitle(count: count)
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: BadgeCollectionViewController, route: LegacyBadgeCollectionViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    private func setTitle(count: Int) {
        let text = Strings.Badge.Collection.titleFormat(count)
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleLight(size: 22) as Any, .foregroundColor: UIColor.gray5]
        )
        let nsText = text as NSString
        attributedText.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: nsText.range(of: Strings.Badge.Collection.titleBold, options: .backwards)
        )
        attributedText.addAttributes(
            [.font: UIFont.appleBold(size: 22) as Any, .foregroundColor: UIColor.tennisGreen],
            range: nsText.range(of: Strings.Badge.Collection.titleHighlightFormat(count), options: .backwards)
        )
        titleLabel.attributedText = attributedText
    }
}

// MARK: Route
extension BadgeCollectionViewController {
    private func handleRoute(_ route: LegacyBadgeCollectionViewModel.Route) {
        switch route {
        case .pop:
            navigationController?.popViewController(animated: true)
        }
    }
}
