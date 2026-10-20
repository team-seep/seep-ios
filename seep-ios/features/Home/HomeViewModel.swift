// swiftlint:disable file_length - 2.4.0에서 홈에 고정·잠든 위시·회고 배너·배지·검색·지도가 함께 들어옴. 기능별 extension 분리는 후속 작업
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
        let didTapSearch = PassthroughSubject<Void, Never>()
        let didTapBadgeCollection = PassthroughSubject<Void, Never>()
        /// 앱이 떠 있을 때 위젯 링크가 저장되면 SceneDelegate 가 보낸다 (GH-50 R-2)
        let handleReservedDeepLink = PassthroughSubject<Void, Never>()
        
        // From FinishNote
        let finishNoteDismissed = PassthroughSubject<Void, Never>()
        /// 셀 메뉴의 "맨 위에 고정" / "고정 해제" (GH-33)
        let didTapPinMenu = PassthroughSubject<Wish, Never>()
        let didTapPlaceMap = PassthroughSubject<Void, Never>()
        
        // 잠든 위시 카드 (GH-30)
        let didTapKeepSleepingWish = PassthroughSubject<Wish, Never>()
        let didTapReleaseSleepingWish = PassthroughSubject<Wish, Never>()
        let didConfirmReleaseSleepingWish = PassthroughSubject<Wish, Never>()
        
        // From WishDetail
        let updateWish = PassthroughSubject<Wish, Never>()
        let deleteWish = PassthroughSubject<Wish, Never>()
        let cancelFinish = PassthroughSubject<Wish, Never>()
        
        // 연말 회고 배너 (GH-34)
        let didTapYearReviewBanner = PassthroughSubject<Void, Never>()
        let didTapCloseYearReviewBanner = PassthroughSubject<Void, Never>()
        let yearReviewDismissed = PassthroughSubject<Void, Never>()
        
        // 앱 잠금 (GH-46)
        let didTapAppLock = PassthroughSubject<Void, Never>()
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
        var badges: [Badge] = []
        /// 리스트 맨 위에 보여줄 잠든 위시. 없으면 카드를 그리지 않는다 (GH-30 R-4)
        var sleepingWish: Wish?
        /// 이번 실행에서 카테고리별로 카드에 올리기로 고른 위시 id — 실행당 카테고리별 1번만 고른다
        var sleepingWishIds: [Category: String] = [:]
        /// 이번 실행에서 카드를 처리한 카테고리 — 다음 잠든 위시를 이어서 띄우지 않는다
        var resolvedSleepingCategories: Set<Category> = []
    }
    
    struct YearReviewBanner: Hashable {
        let year: Int
        let count: Int
    }
    
    enum Route {
        case presentWrite(Category)
        case presentSortBottomSheet(SortOrderBottomSheetViewModel)
        case presentFinishNoteBottomSheet(FinishNoteViewModel)
        case presentBadgeCelebration(BadgeCelebrationViewModel)
        case pushBadgeCollection(BadgeCollectionViewModel)
        case showReleaseSleepingWishAlert(Wish)
        case pushWishDetail(WishDetailReactor)
        case pushWishSearch(WishSearchViewModel)
        case presentYearReview(YearReviewViewModel)
        case pushPlaceMap(PlaceMapViewModel)
        case presentAppLockBottomSheet(AppLockBottomSheetViewModel)
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
        let linkPreviewCache: LinkPreviewCaching
        /// 잠든 위시 판정의 "오늘". 테스트에서 날짜를 고정한다 (GH-30 R-10)
        let dateProvider: () -> Date
        let photoStorage: WishPhotoStorage
        /// 잠금 시트에 넘긴다 (GH-46 R-9)
        let authenticationManager: AuthenticationManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            preference: Preference = .shared,
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current,
            remoteConfigRepository: RemoteConfigRepository = RemoteConfigRepositoryImpl(),
            linkPreviewCache: LinkPreviewCaching = LinkPreviewCache.shared,
            dateProvider: @escaping () -> Date = Date.init,
            photoStorage: WishPhotoStorage = WishPhotoStorageImpl.shared,
            authenticationManager: AuthenticationManagerProtocol = AuthenticationManager.shared
        ) {
            self.wishRepository = wishRepository
            self.preference = preference
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.now = now
            self.calendar = calendar
            self.remoteConfigRepository = remoteConfigRepository
            self.linkPreviewCache = linkPreviewCache
            self.dateProvider = dateProvider
            self.photoStorage = photoStorage
            self.authenticationManager = authenticationManager
        }
    }
}

// swiftlint:disable:next type_body_length - 2.4.0에서 홈에 기능 6개가 함께 들어옴. 기능별 extension 분리는 후속 작업
final class HomeViewModel {
    let input = Input()
    let output = Output()
    lazy var headerViewModel = HomeFilterHeaderViewModel(config: .init(
        viewType: dependency.preference.viewType,
        isAppLockEnabled: dependency.preference.isAppLockEnabled
    ))
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
                owner.initializeBadgesIfNeeded()
                owner.fetchWishDatas()
                owner.handleDeepLinkIfExisted()
            }
            .store(in: &cancellables)
        
        input.handleReservedDeepLink
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
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
        
        input.didTapSearch
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.sendClickLog(objectId: .search)
                owner.pushWishSearch()
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
        
        input.didTapPinMenu
            .withUnretained(self)
            .sink { (owner: HomeViewModel, wish: Wish) in
                owner.togglePin(wish: wish)
            }
            .store(in: &cancellables)
        
        input.didTapPlaceMap
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.pushPlaceMap()
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
        
        input.didTapAppLock
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.presentAppLockBottomSheet()
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
        
        headerViewModel.output.didTapSearch
            .subscribe(input.didTapSearch)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.didTapPlaceMap
            .subscribe(input.didTapPlaceMap)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.didTapAppLock
            .subscribe(input.didTapAppLock)
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
        
        if let banner = state.yearReviewBanner {
            sections.append(.init(type: .yearReview, items: [.yearReviewBanner(year: banner.year, count: banner.count)]))
            sendYearReviewImpressionIfNeeded(banner: banner)
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
    
    /// 위젯 링크는 한 번만 처리하도록, 읽으면 유효하지 않은 링크라도 바로 비운다 (GH-50 R-3, R-4)
    private func handleDeepLinkIfExisted() {
        let reservedDeepLink = dependency.preference.reservedDeepLink
        guard !reservedDeepLink.isEmpty else { return }
        dependency.preference.reservedDeepLink = ""
        
        guard let urlComponents = URLComponents(string: reservedDeepLink),
              urlComponents.host == "add",
              let categoryValue = urlComponents.queryItems?.first(where: { $0.name == "category" })?.value,
              let category = Category(rawValue: categoryValue) else { return }
        
        output.route.send(.presentWrite(category))
    }
    
    private func createWishCellViewModels(wish: Wish) -> HomeWishCellViewModel {
        let config = HomeWishCellViewModel.Config(wish: wish, viewType: dependency.preference.viewType)
        let viewModel = HomeWishCellViewModel(config: config, dependency: .init(photoStorage: dependency.photoStorage))
        viewModel.output.didTapFinish
            .subscribe(input.didTapFinish)
            .store(in: &viewModel.cancellables)
        viewModel.output.didTapPinMenu
            .subscribe(input.didTapPinMenu)
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

    private func togglePin(wish: Wish) {
        guard !wish.isSuccess else { return }
        let category = state.category
        let shouldPin = !wish.isPinned
        // 메뉴는 완료 아닌 위시에만 뜨므로 state.wish 에 이 카테고리의 고정 위시가 모두 있다
        let otherPinnedCount = state.wish.filter { $0.isPinned && $0.id != wish.id }.count
        
        if shouldPin, otherPinnedCount >= Wish.maxPinCountPerCategory {
            output.toast.send(Strings.Home.Pin.limitToast)
            dependency.logManager.sendEvent(event: ImpressionEvent(
                screen: output.screenName,
                objectType: .banner,
                objectId: .pinLimitToast,
                extraParameters: [.category: category.rawValue]
            ))
            return
        }
        
        switch dependency.wishRepository.updatePin(wishId: wish.id, isPinned: shouldPin) {
        case .success:
            if shouldPin {
                sendClickLog(objectId: .pinWish, extraParameters: [
                    .category: category.rawValue,
                    .count: otherPinnedCount + 1
                ])
            } else {
                sendClickLog(objectId: .unpinWish, extraParameters: [.category: category.rawValue])
            }
            // 고정 순서가 바뀌므로 정렬을 다시 적용한다 (R-4)
            fetchWishDatas()
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }
    
    private func finishWish(wish: Wish) {
        guard let targetIndex = state.wish.firstIndex(of: wish) else { return }
        let result = dependency.wishRepository.finishWish(wish: wish)

        switch result {
        case .success(let wish):
            dependency.notificationManager.cancelNotifications(wish: wish)
            state.wish[targetIndex] = wish
            state.yearReviewBanner = makeYearReviewBanner()
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
    
    private func pushWishSearch() {
        let viewModel = WishSearchViewModel(dependency: .init(
            wishRepository: dependency.wishRepository,
            logManager: dependency.logManager
        ))
        // 검색 화면에서 들어간 상세에서 고치거나 지우면 홈 목록도 다시 불러온다 (GH-32 R-8)
        viewModel.output.didChangeWishes
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.fetchWishDatas()
            }
            .store(in: &viewModel.cancellables)
        
        output.route.send(.pushWishSearch(viewModel))
    }
    
    private func pushPlaceMap() {
        sendClickLog(objectId: .placeMap)
        
        let viewModel = PlaceMapViewModel(dependency: .init(
            wishRepository: dependency.wishRepository,
            logManager: dependency.logManager
        ))
        // 지도에서 들어간 상세에서 바뀐 것(장소·삭제·완료 취소)을 홈 목록에도 반영한다
        viewModel.output.didChangeWishes
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                owner.fetchWishDatas()
            }
            .store(in: &viewModel.cancellables)
        
        output.route.send(.pushPlaceMap(viewModel))
    }
    
    private func updateWish(wish: Wish) {
        guard let targetIndex = state.wish.firstIndex(where: { $0.id == wish.id }) else { return }
        state.wish[targetIndex] = wish
        updateDataSource()
    }
    
    private func deleteWish(wish: Wish) {
        // 캘린더 이벤트는 쓰기 전용 권한이라 지울 수 없고, "추가됨" 기록만 지운다 (GH-28 R-8)
        dependency.preference.setCalendarEventId(nil, wishId: wish.id)
        // 홈 스와이프 삭제·상세 삭제 모두 여기로 모인다. 링크 미리보기 캐시도 같이 지운다 (GH-29 R-5)
        dependency.linkPreviewCache.remove(wishId: wish.id)
        // 홈 스와이프 삭제·상세 삭제 모두 여기로 온다. 상세에서 방금 바꾼 사진까지 지우도록 위시 id 로 지운다 (GH-36 R-5)
        dependency.photoStorage.deletePhotos(wishId: wish.id)
        state.badges = calculateBadges()
        guard let targetIndex = state.wish.firstIndex(of: wish) else {
            updateDataSource()
            return
        }
        state.wish.remove(at: targetIndex)
        state.yearReviewBanner = makeYearReviewBanner()
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

// MARK: App lock (GH-46)
extension HomeViewModel {
    private func presentAppLockBottomSheet() {
        sendClickLog(objectId: .appLock)
        let viewModel = AppLockBottomSheetViewModel(dependency: .init(
            preference: dependency.preference,
            authenticationManager: dependency.authenticationManager,
            logManager: dependency.logManager
        ))
        viewModel.output.didChangeAppLock
            .subscribe(headerViewModel.input.updateAppLock)
            .store(in: &viewModel.cancellables)
        output.route.send(.presentAppLockBottomSheet(viewModel))
    }
}
