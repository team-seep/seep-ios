import UIKit

final class HomeViewController: BaseViewController {
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
    
    private func setupUI() {
        view.backgroundColor = Constant.backgroundColor
        view.addSubview(collectionView)
        view.addSubview(gradientView)
        view.addSubview(writeButton)
        collectionView.backgroundColor = Constant.backgroundColor
        collectionView.showsVerticalScrollIndicator = false
        collectionView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.trailing.equalToSuperview()
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
                guard owner.dataSource.sectionIdentifier(for: indexPath.section)?.type != .overview else { return }
                owner.viewModel.input.didTapWish.send(indexPath.item)
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
            case .wish(let headerViewModel):
                if dataSource.itemIdentifier(for: IndexPath(item: 0, section: sectionIndex)) == .empty {
                    let item = NSCollectionLayoutItem(layoutSize: .init(
                        widthDimension: .absolute(HomeEmptyCell.Layout.size.width),
                        heightDimension: .absolute(HomeEmptyCell.Layout.size.height)
                    ))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                        widthDimension: .absolute(HomeEmptyCell.Layout.size.width),
                        heightDimension: .absolute(HomeEmptyCell.Layout.size.height)
                    ), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                    
                    let headerSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(HomeFilterHeaderView.Layout.size.height)
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
                        let item = NSCollectionLayoutItem(layoutSize: .init(
                            widthDimension: .absolute(HomeWishGridCell.Layout.size.width),
                            heightDimension: .absolute(HomeWishGridCell.Layout.size.height)
                        ))
                        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .absolute(HomeWishGridCell.Layout.size.height)
                        ), subitems: [item])
                        group.interItemSpacing = .fixed(15)
                        let section = NSCollectionLayoutSection(group: group)
                        section.interGroupSpacing = 15
                        section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                        
                        let headerSize = NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .absolute(HomeFilterHeaderView.Layout.size.height)
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
                            heightDimension: .absolute(HomeFilterHeaderView.Layout.size.height)
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
        case .pushWishDetail(let reactor):
            pushWishDetail(reactor: reactor)
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
}

extension HomeViewController: WriteDelegate {
    func onSuccessWrite(category: Category) {
        viewModel.input.updateCategory.send(category)
        ToastManager.shared.show(message: Strings.Home.Toast.successWrite)
    }
}
