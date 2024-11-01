import Foundation
import Combine

extension HomeViewModel {
    struct Input {
        let firstLoad = PassthroughSubject<Void, Never>()
        let updateCategory = PassthroughSubject<Category, Never>()
        let didTapSort = PassthroughSubject<Void, Never>()
        let updateOnlyFinished = PassthroughSubject<Bool, Never>()
        let updateViewType = PassthroughSubject<ViewType, Never>()
        let didTapWish = PassthroughSubject<Int, Never>()
        let didTapFinish = PassthroughSubject<Wish, Never>()
        let didTapWrite = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        let dataSource = CurrentValueSubject<[HomeSection], Never>([])
        let route = PassthroughSubject<Route, Never>()
    }
    
    struct State {
        var wishCount: Int?
        var category: Category = .wantToDo
        var sortType: HomeSortOrder = .deadlineOrder
        var isOnlyFinished: Bool = false
        var viewType: ViewType
        var wish: [Wish] = []
    }
    
    enum Route {
        case presentWrite(Category)
        case presentSortBottomSheet
        case pushWishDetail(Wish)
    }
    
    struct Dependency {
        let wishRepository: WishRepository
        let preference: Preference
        
        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            preference: Preference = .shared
        ) {
            self.wishRepository = wishRepository
            self.preference = preference
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
                owner.fetchWishDatas()
            }
            .store(in: &cancellables)
        
        input.didTapSort
            .map { Route.presentSortBottomSheet }
            .subscribe(output.route)
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
                owner.fetchWishDatas()
            }
            .store(in: &cancellables)
        
        input.didTapWish
            .withUnretained(self)
            .sink { (owner: HomeViewModel, index: Int) in
                guard let wish = owner.state.wish[safe: index] else { return }
                
                owner.output.route.send(.pushWishDetail(wish))
            }
            .store(in: &cancellables)
        
        // TODO: didTapFinish
        
        input.didTapWrite
            .withUnretained(self)
            .sink { (owner: HomeViewModel, _) in
                let category = owner.state.category
                owner.output.route.send(.presentWrite(category))
            }
            .store(in: &cancellables)
    }
    
    private func bindHeaderViewModel() {
        headerViewModel.output.updateCategory
            .subscribe(input.updateCategory)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.didTapSortOrder
            .map { Route.presentSortBottomSheet }
            .subscribe(output.route)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.updateOnlyFinished
            .subscribe(input.updateOnlyFinished)
            .store(in: &headerViewModel.cancellables)
        
        headerViewModel.output.updateViewType
            .subscribe(input.updateViewType)
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
        
        let wishItems = state.wish.map {
            let cellViewModel = createWishCellViewModels(wish: $0)
            return HomeSectionItem.wish(cellViewModel)
        }
        sections.append(.init(type: .wish(headerViewModel), items: wishItems))
        
        output.dataSource.send(sections)
    }
    
    private func handleDeepLinkIfExisted() {
        
    }
    
    private func createWishCellViewModels(wish: Wish) -> HomeWishCellViewModel {
        let config = HomeWishCellViewModel.Config(wish: wish, viewType: dependency.preference.viewType)
        let viewModel = HomeWishCellViewModel(config: config)
        viewModel.output.didTapFinish
            .subscribe(input.didTapFinish)
            .store(in: &viewModel.cancellables)
        
        return viewModel
    }
}
