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
        
        // From WishDetail
        let updateWish = PassthroughSubject<Wish, Never>()
        let deleteWish = PassthroughSubject<Wish, Never>()
        let cancelFinish = PassthroughSubject<Wish, Never>()
        
        // 연말 회고 배너 (GH-34)
        let didTapYearReviewBanner = PassthroughSubject<Void, Never>()
        let didTapCloseYearReviewBanner = PassthroughSubject<Void, Never>()
        let yearReviewDismissed = PassthroughSubject<Void, Never>()
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
        var yearReviewBanner: YearReviewBanner?
        var didSendYearReviewImpression = false
    }
    
    struct YearReviewBanner: Hashable {
        let year: Int
        let count: Int
    }
    
    enum Route {
        case presentWrite(Category)
        case presentSortBottomSheet(SortOrderBottomSheetViewModel)
        case presentFinishNoteBottomSheet(FinishNoteViewModel)
        case pushWishDetail(WishDetailReactor)
        case presentYearReview(YearReviewViewModel)
        case showErrorAlert(Error)
    }
    
    struct Dependency {
        let wishRepository: WishRepository
        let preference: Preference
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        /// 오늘. 회고 배너 노출 기간 판정용 (GH-34 R-8)
        let now: () -> Date
        let calendar: Calendar
        /// 회고 배너 노출 기간 (GH-34 R-9)
        let remoteConfigRepository: RemoteConfigRepository

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            preference: Preference = .shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current,
            remoteConfigRepository: RemoteConfigRepository = RemoteConfigRepositoryImpl()
        ) {
            self.wishRepository = wishRepository
            self.preference = preference
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
            self.remoteConfigRepository = remoteConfigRepository
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
        
        input.didTapDelete
            .sink { [weak self] index in
                guard let self,
                      let targetWish = state.wish[safe: index] else { return }
                
                dependency.wishRepository.deleteWish(id: targetWish.id)
                deleteWish(wish: targetWish)
            }
            .store(in: &cancellables)
        
        input.didTapYearReviewBanner
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.presentYearReview()
            }
            .store(in: &cancellables)
        
        input.didTapCloseYearReviewBanner
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.closeYearReviewBanner()
            }
            .store(in: &cancellables)
        
        input.yearReviewDismissed
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                // 회고·목록에서 상세로 들어가 완료 취소·삭제했을 수 있어 다시 읽는다 (R-7)
                owner.fetchWishDatas()
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
        state.yearReviewBanner = makeYearReviewBanner()
        updateDataSource()
    }
    
    private func updateDataSource() {
        var sections: [HomeSection] = []
        
        if let wishCount = state.wishCount {
            sections.append(.init(type: .overview, items: [.overview(category: state.category, count: wishCount)]))
        }
        
        if let banner = state.yearReviewBanner {
            sections.append(.init(type: .yearReview, items: [.yearReviewBanner(year: banner.year, count: banner.count)]))
            sendYearReviewImpressionIfNeeded(banner: banner)
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
            state.yearReviewBanner = makeYearReviewBanner()
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
        guard let targetIndex = state.wish.firstIndex(of: wish) else { return }
        state.wish.remove(at: targetIndex)
        state.yearReviewBanner = makeYearReviewBanner()
        updateDataSource()
    }
    
    private func cancelFinish(wish: Wish) {
        guard let targetIndex = state.wish.firstIndex(of: wish) else { return }
        state.wish[targetIndex].isSuccess = false
        state.wish[targetIndex].finishDate = nil
        state.wish[targetIndex].finishNote = ""
        state.yearReviewBanner = makeYearReviewBanner()
        updateDataSource()
    }
}

// MARK: 연말 회고 배너 (GH-34)
extension HomeViewModel {
    /// Remote Config 노출 기간 안이고, 그 해 배너를 닫지 않았고, 대상 연도 완료가 1개 이상이면 배너를 만든다.
    /// 기간 값을 아직 못 받았거나 틀리면 띄우지 않는다 (R-1, R-2, R-9)
    private func makeYearReviewBanner() -> YearReviewBanner? {
        let calendar = dependency.calendar
        guard let period = dependency.remoteConfigRepository.fetchYearReviewPeriod(),
              let year = period.targetYear(now: dependency.now(), calendar: calendar),
              !dependency.preference.closedYearReviewYears.contains(year),
              let range = YearReviewSummary.dateRange(year: year, calendar: calendar) else { return nil }
        
        let count = dependency.wishRepository.fetchFinishedWishes(from: range.from, to: range.to).count
        guard count > 0 else { return nil }
        return YearReviewBanner(year: year, count: count)
    }
    
    private func sendYearReviewImpressionIfNeeded(banner: YearReviewBanner) {
        guard !state.didSendYearReviewImpression else { return }
        state.didSendYearReviewImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: output.screenName,
            objectType: .banner,
            objectId: .yearReviewBanner,
            extraParameters: [.year: banner.year]
        ))
    }
    
    private func presentYearReview() {
        guard let banner = state.yearReviewBanner else { return }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .banner,
            objectId: .yearReviewBanner,
            extraParameters: [.year: banner.year]
        ))
        
        let viewModel = YearReviewViewModel(
            config: .init(year: banner.year),
            dependency: .init(
                wishRepository: dependency.wishRepository,
                logManager: dependency.logManager,
                calendar: dependency.calendar
            )
        )
        viewModel.output.dismissed
            .subscribe(input.yearReviewDismissed)
            .store(in: &viewModel.cancellables)
        
        output.route.send(.presentYearReview(viewModel))
    }
    
    private func closeYearReviewBanner() {
        guard let banner = state.yearReviewBanner else { return }
        sendClickLog(objectId: .closeYearReviewBanner, extraParameters: [.year: banner.year])
        dependency.preference.closedYearReviewYears.append(banner.year)
        state.yearReviewBanner = nil
        updateDataSource()
    }
}
