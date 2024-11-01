import UIKit

final class HomeViewController: BaseViewController {
    enum Constant {
        static let backgroundColor = UIColor(red: 246/255, green: 247/255, blue: 249/255, alpha: 1)
    }
    
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createCollectionViewLayout()
    )
    
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
    
    private func setupUI() {
        view.backgroundColor = Constant.backgroundColor
        view.addSubview(collectionView)
        collectionView.backgroundColor = Constant.backgroundColor
        collectionView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func bind() {
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
    }
    
//    func bind(reactor: HomeReactor) {
//        // MARK: Action
//        self.homeView.successCountButton.rx.tap
//            .map { Reactor.Action.tapSuccessCountButton }
//            .bind(to: reactor.action)
//            .disposed(by: self.disposeBag)
//        
//        self.homeView.categoryView.rx.tapCategory
//            .map { Reactor.Action.tapCategory($0)}
//            .do(onNext: { _ in
//                FeedbackUtils.feedbackInstance.impactOccurred()
//            })
//            .bind(to: reactor.action)
//            .disposed(by: self.disposeBag)
//        
//        self.homeView.viewTypeButton.rx.tap
//            .map { Reactor.Action.tapViewTypeButton }
//            .do(onNext: { _ in
//                FeedbackUtils.feedbackInstance.impactOccurred()
//            })
//            .bind(to: reactor.action)
//            .disposed(by: self.disposeBag)
//        
//        self.homeView.writeButton.rx.tap
//            .map { Reactor.Action.tapWriteButton }
//            .bind(to: reactor.action)
//            .disposed(by: self.disposeBag)
//        
//        // MARK: State
//        reactor.state
//            .map { ($0.category, $0.wishCount) }
//            .asDriver(onErrorJustReturn: (.wantToDo, 0))
//            .drive(self.homeView.rx.wishCount)
//            .disposed(by: self.disposeBag)
//        
//        reactor.state
//            .map { ($0.category, $0.successCount) }
//            .asDriver(onErrorJustReturn: (.wantToDo, 0))
//            .drive(self.homeView.rx.successCount)
//            .disposed(by: self.disposeBag)
//        
//        reactor.state
//            .map { $0.category }
//            .skip(1)
//            .distinctUntilChanged()
//            .asDriver(onErrorJustReturn: .wantToDo)
//            .do(onNext: { [weak self] category in
//                self?.movePageView(category: category)
//            })
//            .drive(self.homeView.rx.category)
//            .disposed(by: self.disposeBag)
//        
//        reactor.state
//            .map { $0.viewType }
//            .distinctUntilChanged()
//            .asDriver(onErrorJustReturn: .grid)
//            .do(onNext: { [weak self] viewType in
//                self?.setViewType(viewType: viewType)
//            })
//            .drive(self.homeView.rx.viewType)
//            .disposed(by: self.disposeBag)
//    }
//    
//    private func setupPageViewController() {
//        for viewController in self.pageViewControllers {
//            viewController.delegate = self
//        }
//        self.addChild(self.pageViewController)
//        self.pageViewController.delegate = self
//        self.pageViewController.dataSource = self
//        self.homeView.containerView.addSubview(self.pageViewController.view)
//        self.pageViewController.view.snp.makeConstraints { make in
//            make.edges.equalTo(self.homeView.containerView)
//        }
//        self.pageViewController.setViewControllers(
//            [self.pageViewControllers[0]],
//            direction: .forward,
//            animated: false,
//            completion: nil
//        )
//    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
//    private func movePageView(category: Category) {
//        guard let currentPageViewController = self.pageViewController.viewControllers?[0] as? PageItemViewController,
//              let currentIndex = self.pageViewControllers.firstIndex(of: currentPageViewController) else {
//            return
//        }
//        
//        switch category {
//        case .wantToDo:
//            self.pageViewController.setViewControllers(
//                [self.pageViewControllers[0]],
//                direction: .reverse,
//                animated: true,
//                completion: nil
//            )
//        case .wantToGet:
//            self.pageViewController.setViewControllers(
//                [self.pageViewControllers[1]],
//                direction: currentIndex > 1 ? .reverse : .forward,
//                animated: true,
//                completion: nil
//            )
//        case .wantToGo:
//            self.pageViewController.setViewControllers(
//                [self.pageViewControllers[2]],
//                direction: .forward,
//                animated: true,
//                completion: nil
//            )
//        }
//    }
//    
//    private func setViewType(viewType: ViewType) {
//        if let viewControllers = self.pageViewController.viewControllers {
//            if !viewControllers.isEmpty {
//                if let pageItemVC = viewControllers[0] as? PageItemViewController {
//                    pageItemVC.setViewType(viewType: viewType)
//                }
//            }
//        }
//    }
//    
//    private func fetchPageVC() {
//        if let viewControllers = self.pageViewController.viewControllers {
//            if !viewControllers.isEmpty {
//                if let pageItemVC = viewControllers[0] as? PageItemViewController {
//                    pageItemVC.actionFetchData()
//                }
//            }
//        }
//    }
    
    private func showFinishAlert() {
        AlertUtils.show(
            viewController: self,
            title: "home_finish_alert_title".localized,
            message: "home_finish_alert_description".localized
        )
    }
    
    @objc private func willEnterForeground() {
        
    }
    
    func createCollectionViewLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
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
                switch headerViewModel.output.viewType.value {
                case .grid:
                    let item = NSCollectionLayoutItem(layoutSize: .init(
                        widthDimension: .absolute(HomeWishGridCell.Layout.size.width),
                        heightDimension: .absolute(HomeWishGridCell.Layout.size.height)
                    ))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                        widthDimension: .absolute(HomeWishGridCell.Layout.size.width),
                        heightDimension: .absolute(HomeWishGridCell.Layout.size.height)
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
                    sectionHeader.contentInsets = .init(top: 0, leading: 0, bottom: 16, trailing: 0)
                    sectionHeader.pinToVisibleBounds = true
                    section.boundarySupplementaryItems = [sectionHeader]
                    
                    return section
                case .list:
                    let item = NSCollectionLayoutItem(layoutSize: .init(
                        widthDimension: .absolute(HomeWishListCell.Layout.size.width),
                        heightDimension: .absolute(HomeWishListCell.Layout.size.height)
                    ))
                    let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                        widthDimension: .absolute(HomeWishListCell.Layout.size.width),
                        heightDimension: .absolute(HomeWishListCell.Layout.size.height)
                    ), subitems: [item])
                    group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
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
                }
            }
        }
    }
}

// MARK: Route
extension HomeViewController {
    private func handleRoute(_ route: HomeViewModel.Route) {
        switch route {
        case .presentWrite(let category):
            presentWrite(category: category)
        case .presentSortBottomSheet:
            presentSortBottomSheet()
        case .pushWishDetail(let wish):
            pushWishDetail(wish: wish)
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
    
    private func presentSortBottomSheet() {
        // TODO: 채워야 함
    }
    
    private func pushWishDetail(wish: Wish) {
        let viewController = WishDetailViewController.instance(wish: wish, mode: .fromHome)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension HomeViewController: WriteDelegate {
    func onSuccessWrite(category: Category) {
//        self.homeReactor.action.onNext(.viewWillAppear)
//        self.homeReactor.action.onNext(.tapCategory(category))
//        self.fetchPageVC()
    }
}

//extension HomeViewController: PageItemDelegate {
//    func onDismiss() {
//        self.homeReactor.action.onNext(.viewWillAppear)
//    }
//    
//    func onFinishWish() {
//        self.showFinishAlert()
//        self.homeReactor.action.onNext(.viewWillAppear)
//    }
//    
//    func scrollViewWillBeginDragging() {
//        self.homeView.hideWriteButton()
//    }
//    
//    func scrollViewDidEndDragging() {
//        self.homeView.showWriteButton()
//    }
//}
//
//extension HomeViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
//    func pageViewController(
//        _ pageViewController: UIPageViewController,
//        viewControllerBefore viewController: UIViewController
//    ) -> UIViewController? {
//        guard let pageItemViewController = viewController as? PageItemViewController,
//              let index = self.pageViewControllers.firstIndex(of: pageItemViewController) else {
//            return nil
//        }
//        let previousIndex = index - 1
//        
//        guard previousIndex >= 0 else {
//            return nil
//        }
//        
//        guard self.pageViewControllers.count > previousIndex else {
//            return nil
//        }
//        
//        return self.pageViewControllers[previousIndex]
//    }
//    
//    func pageViewController(
//        _ pageViewController: UIPageViewController,
//        viewControllerAfter viewController: UIViewController
//    ) -> UIViewController? {
//        guard let pageItemViewController = viewController as? PageItemViewController,
//              let index = self.pageViewControllers.firstIndex(of: pageItemViewController) else {
//            return nil
//        }
//        let nextIndex = index + 1
//        
//        guard nextIndex < self.pageViewControllers.count else {
//            return nil
//        }
//        
//        guard self.pageViewControllers.count > nextIndex else {
//            return nil
//        }
//        
//        return self.pageViewControllers[nextIndex]
//    }
//    
//    func pageViewController(
//        _ pageViewController: UIPageViewController,
//        didFinishAnimating finished: Bool,
//        previousViewControllers: [UIViewController],
//        transitionCompleted completed: Bool
//    ) {
//        if completed {
//            guard let currentViewController = self.pageViewController.viewControllers?[0] as? PageItemViewController,
//                  let currentIndex = self.pageViewControllers.firstIndex(of: currentViewController) else {
//                return
//            }
//            
//            switch currentIndex {
//            case 0:
//                self.homeView.categoryView.moveActiveButton(category: .wantToDo)
//                Observable.just(HomeReactor.Action.tapCategory(.wantToDo))
//                    .bind(to: self.homeReactor.action)
//                    .disposed(by: self.disposeBag)
//            case 1:
//                self.homeView.categoryView.moveActiveButton(category: .wantToGet)
//                Observable.just(HomeReactor.Action.tapCategory(.wantToGet))
//                    .bind(to: self.homeReactor.action)
//                    .disposed(by: self.disposeBag)
//            case 2:
//                self.homeView.categoryView.moveActiveButton(category: .wantToGo)
//                Observable.just(HomeReactor.Action.tapCategory(.wantToGo))
//                    .bind(to: self.homeReactor.action)
//                    .disposed(by: self.disposeBag)
//            default:
//                break
//            }
//        }
//    }
//}
