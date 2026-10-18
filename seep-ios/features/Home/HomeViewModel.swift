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
        
        // 잠든 위시 카드 (GH-30)
        let didTapKeepSleepingWish = PassthroughSubject<Wish, Never>()
        let didTapReleaseSleepingWish = PassthroughSubject<Wish, Never>()
        let didConfirmReleaseSleepingWish = PassthroughSubject<Wish, Never>()
        
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
        /// 리스트 맨 위에 보여줄 잠든 위시. 없으면 카드를 그리지 않는다 (GH-30 R-4)
        var sleepingWish: Wish?
        /// 이번 실행에서 카테고리별로 카드에 올리기로 고른 위시 id — 실행당 카테고리별 1번만 고른다
        var sleepingWishIds: [Category: String] = [:]
        /// 이번 실행에서 카드를 처리한 카테고리 — 다음 잠든 위시를 이어서 띄우지 않는다
        var resolvedSleepingCategories: Set<Category> = []
    }
    
    enum Route {
        case presentWrite(Category)
        case presentSortBottomSheet(SortOrderBottomSheetViewModel)
        case presentFinishNoteBottomSheet(FinishNoteViewModel)
        case showReleaseSleepingWishAlert(Wish)
        case pushWishDetail(WishDetailReactor)
        case showErrorAlert(Error)
    }
    
    struct Dependency {
        let wishRepository: WishRepository
        let preference: Preference
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        /// 잠든 위시 판정의 "오늘". 테스트에서 날짜를 고정한다 (GH-30 R-10)
        let dateProvider: () -> Date

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            preference: Preference = .shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            dateProvider: @escaping () -> Date = Date.init
        ) {
            self.wishRepository = wishRepository
            self.preference = preference
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.dateProvider = dateProvider
        }
    }
}

final class HomeViewModel {
    let input = Input()
    let output = Output()
    lazy var headerViewModel = HomeFilterHeaderViewModel(config: .init(viewType: dependency.preference.viewType))
    private var state: State
    private var dependency: Dependency
    /// 같은 카드를 다시 그릴 때 셀이 묶인 뷰모델을 그대로 쓰도록 들고 있는다
    private var sleepingWishCardViewModel: HomeSleepingWishCardViewModel?
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
                guard let wish = owner.wish(atItem: index) else { return }
                
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
                      let targetWish = wish(atItem: index) else { return }
                
                dependency.wishRepository.deleteWish(id: targetWish.id)
                deleteWish(wish: targetWish)
            }
            .store(in: &cancellables)
        
        input.didTapKeepSleepingWish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.keepSleepingWish(wish)
            }
            .store(in: &cancellables)
        
        input.didTapReleaseSleepingWish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.output.route.send(.showReleaseSleepingWishAlert(wish))
            }
            .store(in: &cancellables)
        
        input.didConfirmReleaseSleepingWish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.releaseSleepingWish(wish)
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
        updateDataSource()
    }
    
    private func updateDataSource() {
        var sections: [HomeSection] = []
        
        if let wishCount = state.wishCount {
            sections.append(.init(type: .overview, items: [.overview(category: state.category, count: wishCount)]))
        }
        
        refreshSleepingWish()
        var wishItems: [HomeSectionItem] = []
        if let sleepingWish = state.sleepingWish {
            wishItems.append(.sleepingWish(sleepingWishCardViewModel(wish: sleepingWish)))
        }
        wishItems += state.wish.map {
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
    
    /// 위시 섹션의 아이템 위치 → 위시. 맨 위에 잠든 위시 카드가 있으면 한 칸 밀린다
    private func wish(atItem item: Int) -> Wish? {
        let offset = state.sleepingWish == nil ? 0 : 1
        return state.wish[safe: item - offset]
    }
    
    /// 현재 카테고리에 보여줄 잠든 위시를 정한다 (GH-30 R-4, R-5)
    private func refreshSleepingWish() {
        let category = state.category
        guard !state.isOnlyFinished,
              !state.resolvedSleepingCategories.contains(category) else {
            state.sleepingWish = nil
            return
        }
        
        let today = dependency.dateProvider()
        if let wishId = state.sleepingWishIds[category] {
            if let wish = state.wish.first(where: { $0.id == wishId }),
               SleepingWishPolicy.isSleeping(wish, today: today) {
                state.sleepingWish = wish
            } else {
                // 수정·완료·삭제로 더 이상 잠든 위시가 아니면 이번 실행에서는 처리한 것으로 본다
                state.resolvedSleepingCategories.insert(category)
                state.sleepingWish = nil
            }
            return
        }
        
        guard let wish = SleepingWishPolicy.oldestSleepingWish(in: state.wish, today: today) else {
            state.sleepingWish = nil
            return
        }
        state.sleepingWishIds[category] = wish.id
        state.sleepingWish = wish
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .sleepingWishCard,
            extraParameters: [.category: category.rawValue]
        ))
    }
    
    private func sleepingWishCardViewModel(wish: Wish) -> HomeSleepingWishCardViewModel {
        let daysSinceTouched = SleepingWishPolicy.daysSinceTouched(wish, today: dependency.dateProvider())
        if let viewModel = sleepingWishCardViewModel,
           viewModel.output.wish.id == wish.id,
           viewModel.output.caption == Strings.Home.SleepingWish.captionFormat(daysSinceTouched) {
            return viewModel
        }
        
        let viewModel = HomeSleepingWishCardViewModel(config: .init(wish: wish, daysSinceTouched: daysSinceTouched))
        viewModel.output.didTapKeep
            .subscribe(input.didTapKeepSleepingWish)
            .store(in: &viewModel.cancellables)
        viewModel.output.didTapRelease
            .subscribe(input.didTapReleaseSleepingWish)
            .store(in: &viewModel.cancellables)
        sleepingWishCardViewModel = viewModel
        return viewModel
    }
    
    private func keepSleepingWish(_ wish: Wish) {
        switch dependency.wishRepository.markChecked(wishId: wish.id) {
        case .success(let checkedWish):
            if let index = state.wish.firstIndex(where: { $0.id == wish.id }) {
                state.wish[index].lastCheckedAt = checkedWish.lastCheckedAt
            }
            state.resolvedSleepingCategories.insert(wish.category)
            updateDataSource()
            sendClickLog(objectId: .keepSleepingWish, extraParameters: [.category: wish.category.rawValue])
            output.toast.send(Strings.Home.SleepingWish.Toast.keep)
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }
    
    private func releaseSleepingWish(_ wish: Wish) {
        dependency.wishRepository.deleteWish(id: wish.id)
        dependency.notificationManager.cancelNotifications(wish: wish)
        state.wish.removeAll { $0.id == wish.id }
        state.wishCount = dependency.wishRepository.fetchNotFinishCount(category: state.category)
        state.resolvedSleepingCategories.insert(wish.category)
        updateDataSource()
        sendClickLog(objectId: .releaseSleepingWish, extraParameters: [.category: wish.category.rawValue])
        output.toast.send(Strings.Home.SleepingWish.Toast.release)
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
        updateDataSource()
    }
    
    private func cancelFinish(wish: Wish) {
        guard let targetIndex = state.wish.firstIndex(of: wish) else { return }
        state.wish[targetIndex].isSuccess = false
        state.wish[targetIndex].finishDate = nil
        state.wish[targetIndex].finishNote = ""
        updateDataSource()
    }
}
