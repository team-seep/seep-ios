import UIKit

final class HomeViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    enum Constant {
        static let backgroundColor = UIColor(red: 246/255, green: 247/255, blue: 249/255, alpha: 1)
    }
    
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createCollectionViewLayout()
    )
    
    private lazy var gradientView: UIView = {
        let view = UIView()
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(r: 246, g: 247, b: 249, a: 0).cgColor, UIColor(r: 246, g: 247, b: 249, a: 1).cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()
    
    private let writeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .init(top: 15, leading: 30, bottom: 15, trailing: 30)
        let button = UIButton(configuration: config)
        button.backgroundColor = .tennisGreen
        button.layer.cornerRadius = 25
        return button
    }()
    
    private lazy var dataSource = HomeDataSource(
        collectionView: collectionView,
        viewModel: viewModel
    )
    private let viewModel: HomeViewModel
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(viewModel: HomeViewModel) {
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
        registerNotification()
        viewModel.input.firstLoad.send(())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playEmojiAnimationIfCellVisible()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.bounds
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // 폴더블 접기/펴기·회전으로 창 크기가 바뀌면 섹션 provider를 새 폭으로 다시 돌린다
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    private func setupUI() {
        view.backgroundColor = Constant.backgroundColor
        view.addSubview(collectionView)
        view.addSubview(gradientView)
        view.addSubview(writeButton)
        collectionView.backgroundColor = Constant.backgroundColor
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = .init(
            top: 0,
            left: 0,
            bottom: HomeWishListCell.Layout.height + UIUtils.bottomSafeAreaInset,
            right: 0
        )
        collectionView.snp.makeConstraints {
            // 넓은 화면(듀오 안쪽)에서는 최대 폭 기둥으로 가운데 둔다. 아이폰에서는 화면 폭 그대로다
            WideScreenLayout.makeColumnConstraints($0)
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        gradientView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(97)
        }
        
        writeButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(50)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }
    }
    
    private func bind() {
        writeButton.tapPublisher
            .subscribe(viewModel.input.didTapWrite)
            .store(in: &cancellables)
        
        collectionView.willBeginDraggingPublisher
            .withUnretained(self)
            .sink { (owner: HomeViewController, _) in
                owner.hideWriteButton()
            }
            .store(in: &cancellables)
        
        collectionView.didEndDraggingPublisher
            .withUnretained(self)
            .sink { (owner: HomeViewController, _) in
                owner.showWriteButton()
            }
            .store(in: &cancellables)
        
        collectionView.didSelectItemPublisher
            .withUnretained(self)
            .sink { (owner: HomeViewController, indexPath: IndexPath) in
                switch owner.dataSource.sectionIdentifier(for: indexPath.section)?.type {
                case .yearReview:
                    owner.viewModel.input.didTapYearReviewBanner.send(())
                case .wish:
                    owner.viewModel.input.didTapWish.send(indexPath.item)
                case .overview, .none:
                    break
                }
            }
            .store(in: &cancellables)
        
        collectionView.willDisplayCellPublisher
            .main
            .sink { [weak self] (cell: UICollectionViewCell, _) in
                self?.handleWillDisplay(cell: cell)
            }
            .store(in: &cancellables)
        
        collectionView.didEndDisplayingCellPublisher
            .main
            .sink { [weak self] (cell: UICollectionViewCell, _) in
                self?.handleEndDisplay(cell: cell)
            }
            .store(in: &cancellables)
        
        viewModel.output.dataSource
            .main
            .withUnretained(self)
            .sink { (owner: HomeViewController, sections: [HomeSection]) in
                owner.dataSource.reload(sections)
            }
            .store(in: &cancellables)
        
        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: HomeViewController, route: HomeViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
        
        viewModel.output.category
            .removeDuplicates()
            .withUnretained(self)
            .sink { (owner: HomeViewController, category: Category) in
                owner.setWriteButtonTitle(category: category)
            }
            .store(in: &cancellables)
        
        viewModel.output.toast
            .main
            .sink { (message: String) in
                ToastManager.shared.show(message: message)
            }
            .store(in: &cancellables)
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func willEnterForeground() {
        playEmojiAnimationIfCellVisible()
    }
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self, let sectionType = dataSource.sectionIdentifier(for: sectionIndex)?.type else {
                fatalError("정의되지 않은 섹션입니다.")
            }
            
            switch sectionType {
            case .overview:
                let item = NSCollectionLayoutItem(layoutSize: .init(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(HomeOverviewCell.Layout.height)
                ))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(HomeOverviewCell.Layout.height)
                ), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: 22, bottom: 0, trailing: 22)
                
                return section
            case .yearReview:
                let size = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(HomeYearReviewBannerCell.Layout.height)
                )
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: 20, bottom: 8, trailing: 20)
                
                return section
            case .wish(let headerViewModel):
                if dataSource.itemIdentifier(for: IndexPath(item: 0, section: sectionIndex)) == .empty {
                    // 셀 폭 = 컨테이너 폭 - 섹션 inset(20 * 2). 화면이 아니라 컬렉션뷰 폭 기준이라 창 크기가 바뀌어도 맞는다
                    let item = NSCollectionLayoutItem(layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(HomeEmptyCell.Layout.height)
                    ))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(HomeEmptyCell.Layout.height)
                    ), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                    
                    let headerSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(HomeFilterHeaderView.Layout.height)
                    )
                    let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerSize,
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .top
                    )
                    sectionHeader.pinToVisibleBounds = true
                    section.boundarySupplementaryItems = [sectionHeader]
                    
                    return section
                } else {
                    switch headerViewModel.output.viewType.value {
                    case .grid:
                        // 리스트와 같은 기준(컬렉션뷰 전체 폭 - 좌우 20)으로 열 수·셀 크기를 계산한다.
                        // safe area 기준이면 듀오처럼 측면 safe area가 있는 기기에서 헤더 아이콘이 리스트와 어긋난다
                        let horizontalInset: CGFloat = 20
                        let availableWidth = layoutEnvironment.container.contentSize.width - horizontalInset * 2
                        let columnCount = HomeWishGridCell.Layout.columnCount(availableWidth: availableWidth)
                        let itemSize = HomeWishGridCell.Layout.itemSize(availableWidth: availableWidth)
                        let item = NSCollectionLayoutItem(layoutSize: .init(
                            widthDimension: .absolute(itemSize.width),
                            heightDimension: .absolute(itemSize.height)
                        ))
                        // 한 그룹 = 한 줄. 서브아이템을 열 수만큼 명시해 소수점 오차로 줄이 넘어가 1열이 되는 일을 막는다
                        var group: NSCollectionLayoutGroup = NSCollectionLayoutGroup.horizontal(
                            layoutSize: .init(
                                widthDimension: .fractionalWidth(1.0),
                                heightDimension: .absolute(itemSize.height)
                            ),
                            subitems: Array(repeating: item, count: columnCount)
                        )
                        group.interItemSpacing = .fixed(HomeWishGridCell.Layout.spacing)
                        if case .sleepingWish = dataSource.itemIdentifier(for: IndexPath(item: 0, section: sectionIndex)) {
                            let snapshot = dataSource.snapshot()
                            let itemCount = snapshot.numberOfItems(inSection: snapshot.sectionIdentifiers[sectionIndex])
                            group = HomeSleepingWishCell.Layout.gridGroupWithCard(availableWidth: availableWidth, wishCount: itemCount - 1)
                        }
                        let section = NSCollectionLayoutSection(group: group)
                        section.contentInsetsReference = .none
                        section.interGroupSpacing = HomeWishGridCell.Layout.spacing
                        section.contentInsets = .init(top: 0, leading: horizontalInset, bottom: 0, trailing: horizontalInset)
                        
                        let headerSize = NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .absolute(HomeFilterHeaderView.Layout.height)
                        )
                        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                            layoutSize: headerSize,
                            elementKind: UICollectionView.elementKindSectionHeader,
                            alignment: .top
                        )
                        sectionHeader.pinToVisibleBounds = true
                        section.boundarySupplementaryItems = [sectionHeader]
                        
                        return section
                    case .list:
                        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
                        configuration.backgroundColor = .clear
                        configuration.showsSeparators = false
                        
                        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                            // 잠든 위시 카드는 스와이프 삭제 대상이 아니다 (GH-30 R-6)
                            if case .sleepingWish = self?.dataSource.itemIdentifier(for: indexPath) { return nil }
                            let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
                                self?.deleteItem(at: indexPath, completion: completion)
                            }
                            deleteAction.image = UIImage(systemName: "trash")
                            
                            return UISwipeActionsConfiguration(actions: [deleteAction])
                        }
                        
                        let section = NSCollectionLayoutSection.list(
                            using: configuration,
                            layoutEnvironment: layoutEnvironment
                        )
                        section.interGroupSpacing = 10
                        section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                        
                        // 헤더 추가
                        let headerSize = NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .absolute(HomeFilterHeaderView.Layout.height)
                        )
                        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                            layoutSize: headerSize,
                            elementKind: UICollectionView.elementKindSectionHeader,
                            alignment: .top
                        )
                        sectionHeader.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                        section.boundarySupplementaryItems = [sectionHeader]
                        
                        
                        return section
                    }
                }
            }
        }
    }
    
    private func showWriteButton() {
        UIView.transition(with: writeButton, duration: 0.3, options: .curveEaseInOut) { [weak self] in
            self?.writeButton.alpha = 1.0
            self?.writeButton.transform = .identity
        }
    }
    
    private func hideWriteButton() {
        UIView.transition(with: writeButton, duration: 0.3, options: .curveEaseInOut) { [weak self] in
            self?.writeButton.alpha = 0.0
            self?.writeButton.transform = .init(translationX: 0, y: 100)
        }
    }
    
    private func setWriteButtonTitle(category: Category) {
        let title: String
        switch category {
        case .wantToDo:
            title = Strings.Home.WriteButton.wantToDo
        case .wantToGet:
            title = Strings.Home.WriteButton.wantToGet
        case .wantToGo:
            title = Strings.Home.WriteButton.wantToGo
        }
        
        writeButton.configuration?.attributedTitle = AttributedString(title, attributes: .init([
            .font: UIFont.appleExtraBold(size: 17) as Any,
            .foregroundColor: UIColor.white
        ]))
    }
    
    private func handleWillDisplay(cell: UICollectionViewCell) {
        if let overviewCell = cell as? HomeOverviewCell {
            overviewCell.playEmojiAnimation()
        }
    }
    
    private func handleEndDisplay(cell: UICollectionViewCell) {
        if let overviewCell = cell as? HomeOverviewCell {
            overviewCell.stopEmojiAnimation()
        }
    }
    
    private func playEmojiAnimationIfCellVisible() {
        collectionView.visibleCells.compactMap {
            $0 as? HomeOverviewCell
        }.forEach {
            $0.playEmojiAnimation()
        }
    }
    
    private func deleteItem(at indexPath: IndexPath, completion: @escaping ((Bool) -> Void)) {
        // 삭제 확인 알럿 표시
        let alert = UIAlertController(
            title: "삭제 확인",
            message: "이 위시를 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.viewModel.input.didTapDelete.send(indexPath.item)
            completion(true)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completion(true)
        }
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// MARK: Route
extension HomeViewController {
    private func handleRoute(_ route: HomeViewModel.Route) {
        switch route {
        case .presentWrite(let category):
            presentWrite(category: category)
        case .presentSortBottomSheet(let viewModel):
            presentSortBottomSheet(viewModel: viewModel)
        case .presentFinishNoteBottomSheet(let viewModel):
            presentFinishNoteBottomSheet(viewModel: viewModel)
        case .presentBadgeCelebration(let viewModel):
            presentBadgeCelebration(viewModel: viewModel)
        case .pushBadgeCollection(let viewModel):
            pushBadgeCollection(viewModel: viewModel)
        case .showReleaseSleepingWishAlert(let wish):
            showReleaseSleepingWishAlert(wish: wish)
        case .pushWishDetail(let reactor):
            pushWishDetail(reactor: reactor)
        case .pushWishSearch(let viewModel):
            pushWishSearch(viewModel: viewModel)
        case .presentYearReview(let viewModel):
            presentYearReview(viewModel: viewModel)
        case .pushPlaceMap(let viewModel):
            navigationController?.pushViewController(PlaceMapViewController(viewModel: viewModel), animated: true)
        case .presentAppLockBottomSheet(let viewModel):
            presentPanModal(AppLockBottomSheetViewController(viewModel: viewModel))
        case .showErrorAlert(let error):
            showErrorAlert(error)
        }
    }
    
    private func presentWrite(category: Category) {
        let viewController = WriteViewController.instance(category: category)
        viewController.delegate = self
        
        let navigationViewController = UINavigationController(rootViewController: viewController).then {
            $0.isNavigationBarHidden = true
            $0.modalPresentationStyle = .overCurrentContext
        }
        
        present(navigationViewController, animated: true)
    }
    
    private func presentSortBottomSheet(viewModel: SortOrderBottomSheetViewModel) {
        let viewController = SortOrderBottomSheetViewController(viewModel: viewModel)
        presentPanModal(viewController)
    }
    
    private func presentFinishNoteBottomSheet(viewModel: FinishNoteViewModel) {
        let viewController = FinishNoteBottomSheetViewController(viewModel: viewModel)
        presentPanModal(viewController)
    }
    
    private func presentBadgeCelebration(viewModel: BadgeCelebrationViewModel) {
        let viewController = BadgeCelebrationBottomSheetViewController(viewModel: viewModel)
        presentPanModal(viewController)
    }
    
    /// 축하 시트에서 왔으면 시트를 먼저 닫고 push 한다 (GH-35 R-10)
    private func pushBadgeCollection(viewModel: BadgeCollectionViewModel) {
        let viewController = BadgeCollectionViewController(viewModel: viewModel)
        guard let presentedViewController else {
            navigationController?.pushViewController(viewController, animated: true)
            return
        }
        presentedViewController.dismiss(animated: true) { [weak self] in
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func showReleaseSleepingWishAlert(wish: Wish) {
        let alert = UIAlertController(
            title: Strings.Home.SleepingWish.Alert.title,
            message: Strings.Home.SleepingWish.Alert.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.Home.SleepingWish.Alert.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Strings.Home.SleepingWish.Alert.release, style: .destructive) { [weak self] _ in
            self?.viewModel.input.didConfirmReleaseSleepingWish.send(wish)
        })
        present(alert, animated: true)
    }
    
    private func pushWishDetail(reactor: WishDetailReactor) {
        let mode: DetailMode
        if reactor.initialState.wish.isSuccess {
            mode = .fromFinish
        } else {
            mode = .fromHome
        }
        let viewController = WishDetailViewController(reactor: reactor, mode: mode)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func pushWishSearch(viewModel: WishSearchViewModel) {
        let viewController = WishSearchViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func presentYearReview(viewModel: YearReviewViewModel) {
        // 목록·상세로 push 하려고 내비게이션으로 감싼다. 바는 각 화면이 직접 그린다
        let navigationController = UINavigationController(rootViewController: YearReviewViewController(viewModel: viewModel))
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}

extension HomeViewController: WriteDelegate {
    func onSuccessWrite(category: Category) {
        viewModel.input.updateCategory.send(category)
        ToastManager.shared.show(message: Strings.Home.Toast.successWrite)
    }
}
