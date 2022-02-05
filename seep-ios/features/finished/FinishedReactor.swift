import RxSwift
import RxCocoa
import ReactorKit

final class FinishedReactor: Reactor {
    enum Action {
        case viewDidLoad
        case tapViewType
        case tapWish(index: Int)
    }
    
    enum Mutation {
        case fetchFinishedWishList([Wish])
        case setViewType(ViewType)
        case setEmptyViewHidden(Bool)
        case pushWishDetail(wish: Wish)
    }
    
    struct State {
        var finishedWishiList: [Wish] = []
        var finishedCount: Int = 0
        var isHiddenEmptyView: Bool = false
        var viewType: ViewType = .list
    }
    
    let initialState = State()
    let pushWishDetailPublisher = PublishRelay<Wish>()
    let category: Category
    private let wishService: WishServiceProtocol
    private let userDefaults: UserDefaultsUtils
    
    init(
        category: Category,
        wishService: WishServiceProtocol,
        userDefaults: UserDefaultsUtils
    ) {
        self.category = category
        self.wishService = wishService
        self.userDefaults = userDefaults
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let finishedWishList = self.wishService.fetchFinishedWishes(category: self.category)
            
            return .merge([
                .just(.fetchFinishedWishList(finishedWishList)),
                .just(.setViewType(self.userDefaults.getViewType())),
                .just(.setEmptyViewHidden(!finishedWishList.isEmpty))
            ])
            
        case .tapViewType:
            return .just(.setViewType(self.currentState.viewType.toggle()))
            
        case .tapWish(let index):
            let tappedWish = self.currentState.finishedWishiList[index]
            
            return .just(.pushWishDetail(wish: tappedWish))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .fetchFinishedWishList(let finishedWishList):
            newState.finishedWishiList = finishedWishList
            newState.finishedCount = finishedWishList.count
            
        case .setViewType(let viewType):
            newState.viewType = viewType
            
        case .setEmptyViewHidden(let isHidden):
            newState.isHiddenEmptyView = isHidden
            
        case .pushWishDetail(let wish):
            self.pushWishDetailPublisher.accept(wish)
        }
        
        return newState
    }
}
