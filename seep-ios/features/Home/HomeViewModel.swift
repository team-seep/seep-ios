import Foundation
import Combine

extension HomeViewModel {
    struct Input {
        let firstLoad = PassthroughSubject<Void, Never>()
        let reload = PassthroughSubject<Category, Never>()
        let updateCategory = PassthroughSubject<Category, Never>()
        let didTapSortOrder = PassthroughSubject<Void, Never>()
        let updateSortOrder = PassthroughSubject<HomeSortOrder, Never>()
        let updateOnlyFinished = PassthroughSubject<Bool, Never>()
        let updateViewType = PassthroughSubject<ViewType, Never>()
        let didTapWish = PassthroughSubject<Int, Never>()
        let didTapFinish = PassthroughSubject<Wish, Never>()
        let didTapWrite = PassthroughSubject<Void, Never>()
        let didTapDelete = PassthroughSubject<Int, Never>()
        let didTapBadgeCollection = PassthroughSubject<Void, Never>()
        
        // From FinishNote
        let finishNoteDismissed = PassthroughSubject<Void, Never>()
        
        // From WishDetail
        let updateWish = PassthroughSubject<Wish, Never>()
        let deleteWish = PassthroughSubject<Wish, Never>()
        let cancelFinish = PassthroughSubject<Wish, Never>()
    }
    
    struct Output {
        let screenName: ScreenName = .home
        let category = CurrentValueSubject<Category, Never>(.wantToDo)
        let dataSource = CurrentValueSubject<[HomeSection], Never>([])
        let toast = PassthroughSubject<String, Never>()
        let route = PassthroughSubject<Route, Never>()
    }
    
    struct State {
        var wishCount: Int?
        var category: Category = .wantToDo
        var sortType: HomeSortOrder = .deadlineOrder
        var isOnlyFinished: Bool = false
        var viewType: ViewType
        var wish: [Wish] = []
        var badges: [Badge] = []
    }
    
    enum Route {
        case presentWrite(Category)
        case presentSortBottomSheet(SortOrderBottomSheetViewModel)
        case presentFinishNoteBottomSheet(FinishNoteViewModel)
        case presentBadgeCelebration(BadgeCelebrationViewModel)
        case pushBadgeCollection(BadgeCollectionViewModel)
        case pushWishDetail(WishDetailReactor)
        case showErrorAlert(Error)
    }
    
    struct Dependency {
        let wishRepository: WishRepository
        let preference: Preference
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            preference: Preference = .shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.wishRepository = wishRepository
            self.preference = preference
            self.notificationManager = notificationManager
            self.logManager = logManager
        }
    }
}

final class HomeViewModel {
    let input = Input()
    let output = Output()
    lazy var headerViewModel = HomeFilterHeaderViewModel(config: .init(viewType: dependency.preference.viewType))
    private var state: State
    private var dependency: Dependency
    private var cancellables = Set<AnyCancellable>()
    
    init(dependency: Dependency = Dependency()) {
        self.state = State(viewType: dependency.preference.viewType)
        self.dependency = dependency
        
        bind()
        bindHeaderViewModel()
    }
    
    private func bind() {
        input.firstLoad
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.initializeBadgesIfNeeded()
                owner.fetchWishDatas()
                owner.handleDeepLinkIfExisted()
            }
            .store(in: &cancellables)
        
        input.updateCategory
            .withUnretained(self)
            .sink { (owner: HomeViewModel, category: Category) in
                owner.state.category = category
                owner.output.category.send(category)
                owner.fetchWishDatas()
            }
            .store(in: &cancellables)
        
        input.didTapSortOrder
            .withUnretained(self)
            .sink(receiveValue: { (owner: HomeViewModel, _) in
                owner.presentSortOrderBottomSheet()
            })
            .store(in: &cancellables)
        
        input.updateSortOrder
            .withUnretained(self)
            .sink { (owner: HomeViewModel, sortOrder: HomeSortOrder) in
                owner.state.sortType = sortOrder
                owner.fetchWishDatas()
            }
            .store(in: &cancellables)
        
        input.updateOnlyFinished
            .withUnretained(self)
            .sink { (owner: HomeViewModel, isOnlyFinished: Bool) in
                owner.state.isOnlyFinished = isOnlyFinished
                owner.fetchWishDatas()
            }
            .store(in: &cancellables)
        
        input.updateViewType
            .withUnretained(self)
            .sink { (owner: HomeViewModel, viewType: ViewType) in
                owner.state.viewType = viewType
                owner.dependency.preference.viewType = viewType
                owner.updateDataSource()
            }
            .store(in: &cancellables)
        
        input.didTapWish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, index: Int) in
                guard let wish = owner.state.wish[safe: index] else { return }
                
                owner.pushWishDetail(wish: wish)
            }
            .store(in: &cancellables)
        
        input.didTapFinish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.sendClickLog(objectId: .finish, extraParameters: [.category: owner.state.category.rawValue])
                owner.finishWish(wish: wish)
            }
            .store(in: &cancellables)
        
        input.didTapWrite
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                let category = owner.state.category
                owner.sendClickLog(objectId: .write, extraParameters: [.category: category.rawValue])
                owner.output.route.send(.presentWrite(category))
            }
            .store(in: &cancellables)
        
        input.updateWish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.updateWish(wish: wish)
            }
            .store(in: &cancellables)
        
        input.deleteWish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.deleteWish(wish: wish)
            }
            .store(in: &cancellables)
        
        input.cancelFinish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.cancelFinish(wish: wish)
            }
            .store(in: &cancellables)
        
        input.didTapBadgeCollection
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.sendClickLog(objectId: .badgeCollection)
                owner.pushBadgeCollection()
            }
            .store(in: &cancellables)
        
        input.finishNoteDismissed
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.presentBadgeCelebrationIfNeeded()
            }
            .store(in: &cancellables)
        
        input.didTapDelete
            .sink { [weak self] index in
                guard let self,
                      let targetWish = state.wish[safe: index] else { return }
                
                dependency.wishRepository.deleteWish(id: targetWish.id)
                deleteWish(wish: targetWish)
            }
            .store(in: &cancellables)
    }
    
    private func bindHeaderViewModel() {
        headerViewModel.output.updateCategory
            .subscribe(input.updateCategory)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.didTapSortOrder
            .subscribe(input.didTapSortOrder)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.updateOnlyFinished
            .subscribe(input.updateOnlyFinished)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.updateViewType
            .subscribe(input.updateViewType)
            .store(in: &headerViewModel.cancellables)
        
        input.updateSortOrder
            .subscribe(headerViewModel.input.selectSortOrder)
            .store(in: &headerViewModel.cancellables)
        
        input.updateCategory
            .subscribe(headerViewModel.input.updateCategory)
            .store(in: &headerViewModel.cancellables)
    }
    
    private func fetchWishDatas() {
        let notFinishCount = dependency.wishRepository.fetchNotFinishCount(category: state.category)
        let wishes = dependency.wishRepository.fetchWishes(
            category: state.category,
            sort: state.sortType,
            isOnlyFinished: state.isOnlyFinished
        )
        
        state.wishCount = notFinishCount
        state.wish = wishes
        state.badges = calculateBadges()
        updateDataSource()
    }
    
    private func updateDataSource() {
        var sections: [HomeSection] = []
        
        if let wishCount = state.wishCount {
            let badgeCount = state.badges.filter(\.isEarned).count
            sections.append(.init(type: .overview, items: [
                .overview(category: state.category, count: wishCount, badgeCount: badgeCount)
            ]))
        }
        
        let wishItems = state.wish.map {
            let cellViewModel = createWishCellViewModels(wish: $0)
            return HomeSectionItem.wish(cellViewModel)
        }
        
        if wishItems.isNotEmpty {
            sections.append(.init(type: .wish(headerViewModel), items: wishItems))
        } else {
            sections.append(.init(type: .wish(headerViewModel), items: [.empty]))
        }
        
        output.dataSource.send(sections)
    }
    
    private func handleDeepLinkIfExisted() {
        let reservedDeepLink = dependency.preference.reservedDeepLink
        guard !reservedDeepLink.isEmpty,
              let urlComponents = URLComponents(string: reservedDeepLink),
              urlComponents.host == "add" else { return }
        
        if let categoryQuery = urlComponents.queryItems?.first(where: { $0.name == "category" }),
           let category = Category(rawValue: categoryQuery.value ?? "") {
            
            output.route.send(.presentWrite(category))
        }
    }
    
    private func createWishCellViewModels(wish: Wish) -> HomeWishCellViewModel {
        let config = HomeWishCellViewModel.Config(wish: wish, viewType: dependency.preference.viewType)
        let viewModel = HomeWishCellViewModel(config: config)
        viewModel.output.didTapFinish
            .subscribe(input.didTapFinish)
            .store(in: &viewModel.cancellables)
        
        return viewModel
    }
    
    private func presentSortOrderBottomSheet() {
        let viewModel = SortOrderBottomSheetViewModel()
        viewModel.output.didTapSortOrder
            .subscribe(input.updateSortOrder)
            .store(in: &viewModel.cancellables)
        
        output.route.send(.presentSortBottomSheet(viewModel))
    }
    
    private func sendClickLog(objectId: LogObjectId, extraParameters: [ParameterName: Any]? = nil) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .button,
            objectId: objectId,
            extraParameters: extraParameters
        ))
    }

    private func finishWish(wish: Wish) {
        guard let targetIndex = state.wish.firstIndex(of: wish) else { return }
        let result = dependency.wishRepository.finishWish(wish: wish)

        switch result {
        case .success(let wish):
            dependency.notificationManager.cancelNotifications(wish: wish)
            state.wish[targetIndex] = wish
            state.badges = calculateBadges()
            updateDataSource()
            output.toast.send(Strings.Home.Toast.finishWish)
            presentFinishNoteBottomSheet(wish: wish)
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }
    
    private func presentFinishNoteBottomSheet(wish: Wish) {
        let viewModel = FinishNoteViewModel(
            config: .init(wish: wish),
            dependency: .init(wishRepository: dependency.wishRepository, logManager: dependency.logManager)
        )
        viewModel.output.didSaveNote
            .subscribe(input.updateWish)
            .store(in: &viewModel.cancellables)
        viewModel.output.dismissed
            .subscribe(input.finishNoteDismissed)
            .store(in: &viewModel.cancellables)
        
        output.route.send(.presentFinishNoteBottomSheet(viewModel))
    }
    
    private func pushWishDetail(wish: Wish) {
        let reactor = WishDetailReactor(wish: wish, wishService: WishService())
        reactor.updateWishPublisher
            .subscribe(input.updateWish)
            .store(in: &reactor.cancellables)
        
        reactor.deleteWishPublisher
            .subscribe(input.deleteWish)
            .store(in: &reactor.cancellables)
        
        reactor.cancelFinishPublisher
            .subscribe(input.cancelFinish)
            .store(in: &reactor.cancellables)
        
        output.route.send(.pushWishDetail(reactor))
    }
    
    private func updateWish(wish: Wish) {
        guard let targetIndex = state.wish.firstIndex(where: { $0.id == wish.id }) else { return }
        state.wish[targetIndex] = wish
        updateDataSource()
    }
    
    private func deleteWish(wish: Wish) {
        state.badges = calculateBadges()
        guard let targetIndex = state.wish.firstIndex(of: wish) else {
            updateDataSource()
            return
        }
        state.wish.remove(at: targetIndex)
        updateDataSource()
    }
    
    private func cancelFinish(wish: Wish) {
        state.badges = calculateBadges()
        guard let targetIndex = state.wish.firstIndex(of: wish) else {
            updateDataSource()
            return
        }
        state.wish[targetIndex].isSuccess = false
        state.wish[targetIndex].finishDate = nil
        state.wish[targetIndex].finishNote = ""
        updateDataSource()
    }
}

// MARK: Badge (GH-35)
extension HomeViewModel {
    private func calculateBadges() -> [Badge] {
        return BadgeCalculator.calculate(finishedWishes: dependency.wishRepository.fetchAllFinishedWishes())
    }
    
    /// 업데이트 직후 첫 진입: 이미 얻은 배지는 축하 없이 축하함으로 넘긴다 (R-8)
    private func initializeBadgesIfNeeded() {
        guard !dependency.preference.isBadgeInitialized else { return }
        let earnedIds = calculateBadges().filter(\.isEarned).map(\.type.rawValue)
        dependency.preference.celebratedBadgeIds.formUnion(earnedIds)
        dependency.preference.isBadgeInitialized = true
    }
    
    /// 소감 시트가 닫힌 뒤, 아직 축하하지 않은 배지가 있으면 축하 시트를 띄우고 바로 축하함에 넣는다 (R-6, R-7, R-9)
    private func presentBadgeCelebrationIfNeeded() {
        let badges = calculateBadges()
        state.badges = badges
        let celebratedIds = dependency.preference.celebratedBadgeIds
        let newBadges = badges.filter { $0.isEarned && !celebratedIds.contains($0.type.rawValue) }
        guard newBadges.isNotEmpty else { return }
        
        dependency.preference.celebratedBadgeIds.formUnion(newBadges.map(\.type.rawValue))
        
        let viewModel = BadgeCelebrationViewModel(
            config: .init(badges: newBadges, finishedCount: newBadges[0].finishedCount),
            dependency: .init(logManager: dependency.logManager)
        )
        viewModel.output.didTapViewBadges
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.pushBadgeCollection()
            }
            .store(in: &viewModel.cancellables)
        
        output.route.send(.presentBadgeCelebration(viewModel))
    }
    
    private func pushBadgeCollection() {
        let viewModel = BadgeCollectionViewModel(dependency: .init(wishRepository: dependency.wishRepository))
        output.route.send(.pushBadgeCollection(viewModel))
    }
}
