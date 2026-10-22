import UIKit
import Combine

import CombineCocoa
import SnapKit

/// 올해 이룬 싶 회고 화면 (GH-34 R-3~R-6). 홈 배너에서 전체 화면 모달로 열린다.
final class YearReviewViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let shareButtonHeight: CGFloat = 50
        static let shareButtonBottomInset: CGFloat = 24
    }

    private let viewModel: LegacyYearReviewViewModel

    private let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icClose.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray5
        button.accessibilityLabel = Strings.YearReview.close
        return button
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentView = UIView()

    private let cardView = YearReviewCardView()

    private let showAllButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.YearReview.showAll, for: .normal)
        button.setTitleColor(.seepBlue, for: .normal)
        button.titleLabel?.font = .appleBold(size: 14)
        return button
    }()

    private let shareButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .init(top: 0, leading: 36, bottom: 0, trailing: 36)
        config.attributedTitle = AttributedString(Strings.YearReview.share, attributes: .init([
            .font: UIFont.appleExtraBold(size: 17) as Any,
            .foregroundColor: UIColor.white
        ]))
        let button = UIButton(configuration: config)
        button.backgroundColor = .tennisGreen
        button.layer.cornerRadius = Layout.shareButtonHeight / 2
        return button
    }()

    init(viewModel: LegacyYearReviewViewModel) {
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
        view.addSubViews([scrollView, closeButton, shareButton])
        scrollView.addSubview(contentView)
        contentView.addSubViews([cardView, showAllButton])

        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.trailing.equalTo(view.safeAreaLayoutGuide).offset(-8)
            $0.size.equalTo(44)
        }

        scrollView.snp.makeConstraints {
            WideScreenLayout.makeColumnConstraints($0)
            $0.top.equalTo(closeButton.snp.bottom)
            $0.bottom.equalToSuperview()
        }
        // 공유 버튼에 가리지 않도록 아래 여백을 둔다
        scrollView.contentInset.bottom = Layout.shareButtonHeight + Layout.shareButtonBottomInset + 16

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }

        showAllButton.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview()
        }

        shareButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Layout.shareButtonHeight)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Layout.shareButtonBottomInset)
        }
    }

    private func bind() {
        closeButton.tapPublisher
            .subscribe(viewModel.input.didTapClose)
            .store(in: &cancellables)

        showAllButton.tapPublisher
            .subscribe(viewModel.input.didTapShowAll)
            .store(in: &cancellables)

        shareButton.tapPublisher
            .withUnretained(self)
            .compactMap { (owner: YearReviewViewController, _) in
                LegacyYearReviewImageRenderer.render(cardView: owner.cardView).pngData()
            }
            .subscribe(viewModel.input.didTapShare)
            .store(in: &cancellables)

        viewModel.output.summary
            .compactMap { $0 }
            .main
            .withUnretained(self)
            .sink { (owner: YearReviewViewController, summary: YearReviewSummary) in
                owner.cardView.bind(summary: summary)
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: YearReviewViewController, route: LegacyYearReviewViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Route
extension YearReviewViewController {
    private func handleRoute(_ route: LegacyYearReviewViewModel.Route) {
        switch route {
        case .presentShareSheet(let imageData):
            presentShareSheet(imageData: imageData)
        case .pushYearReviewList(let viewModel):
            pushYearReviewList(viewModel: viewModel)
        case .dismiss:
            dismiss(animated: true)
        }
    }

    private func presentShareSheet(imageData: Data) {
        guard let image = UIImage(data: imageData, scale: LegacyYearReviewImageRenderer.scale) else { return }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        // 아이패드·넓은 화면에서는 팝오버로 뜨므로 기준 뷰를 준다
        activityViewController.popoverPresentationController?.sourceView = shareButton
        present(activityViewController, animated: true)
    }

    private func pushYearReviewList(viewModel: LegacyYearReviewListViewModel) {
        let viewController = YearReviewListViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
