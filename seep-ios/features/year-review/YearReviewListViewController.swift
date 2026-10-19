import UIKit
import Combine

import CombineCocoa
import SnapKit

/// 올해 이룬 싶 모두 보기 (GH-34 R-6). 회고 화면에서 push 된다.
final class YearReviewListViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private typealias Section = YearReviewListViewModel.Section
    private typealias Item = YearReviewListViewModel.Item

    private let viewModel: YearReviewListViewModel

    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icBack.image, for: .normal)
        button.accessibilityLabel = Strings.YearReview.List.back
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .gray2
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register([YearReviewListCell.self])
        collectionView.register(
            YearReviewListHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: YearReviewListHeaderView.kind
        )
        collectionView.register(
            YearReviewListMonthHeaderView.self,
            forSupplementaryViewOfKind: YearReviewListMonthHeaderView.kind,
            withReuseIdentifier: YearReviewListMonthHeaderView.kind
        )
        return collectionView
    }()

    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Item>(
        collectionView: collectionView
    ) { collectionView, indexPath, item in
        let cell: YearReviewListCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        cell.bind(item: item)
        return cell
    }

    init(viewModel: YearReviewListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupSupplementaryViews()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.input.viewWillAppear.send(())
    }

    private func setupUI() {
        view.backgroundColor = .gray2
        view.addSubViews([backButton, collectionView])

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.size.equalTo(44)
        }

        collectionView.snp.makeConstraints {
            WideScreenLayout.makeColumnConstraints($0)
            $0.top.equalTo(backButton.snp.bottom)
            $0.bottom.equalToSuperview()
        }
    }

    private func setupSupplementaryViews() {
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }
            if kind == YearReviewListMonthHeaderView.kind {
                let view = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: YearReviewListMonthHeaderView.kind,
                    for: indexPath
                ) as? YearReviewListMonthHeaderView
                if let section = dataSource.sectionIdentifier(for: indexPath.section) {
                    view?.bind(month: section.month, count: section.items.count)
                }
                return view
            }
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: YearReviewListHeaderView.kind,
                for: indexPath
            ) as? YearReviewListHeaderView
            view?.bind(year: viewModel.output.year, count: viewModel.output.totalCount.value)
            return view
        }
    }

    private func bind() {
        backButton.tapPublisher
            .subscribe(viewModel.input.didTapBack)
            .store(in: &cancellables)

        collectionView.didSelectItemPublisher
            .subscribe(viewModel.input.didTapWish)
            .store(in: &cancellables)

        viewModel.output.sections
            .main
            .withUnretained(self)
            .sink { (owner: YearReviewListViewController, sections: [Section]) in
                owner.apply(sections: sections)
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: YearReviewListViewController, route: YearReviewListViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    private func apply(sections: [Section]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        sections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.items, toSection: $0)
        }
        // 첫 섹션 위 헤드라인의 총 개수도 다시 그리도록 전체를 다시 그린다
        dataSource.applySnapshotUsingReloadData(snapshot)
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(YearReviewListCell.Layout.height)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10
            section.contentInsets = .init(top: 0, leading: 20, bottom: 12, trailing: 20)

            let monthHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(42)),
                elementKind: YearReviewListMonthHeaderView.kind,
                alignment: .top
            )
            section.boundarySupplementaryItems = [monthHeader]
            return section
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let headline = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        configuration.boundarySupplementaryItems = [headline]
        layout.configuration = configuration
        return layout
    }
}

// MARK: Route
extension YearReviewListViewController {
    private func handleRoute(_ route: YearReviewListViewModel.Route) {
        switch route {
        case .pushWishDetail(let reactor):
            let viewController = WishDetailViewController(reactor: reactor, mode: .fromFinish)
            navigationController?.pushViewController(viewController, animated: true)
        case .pop:
            navigationController?.popViewController(animated: true)
        }
    }
}
