import RxSwift
import RxCocoa
import ReactorKit

final class PageItemReactor: Reactor {
    enum Action {
        case viewWillAppear
        case setViewType(ViewType)
        case tapWish(index: Int)
        case tapFinishButton(index: Int)
    }
    
    enum Mutation {
        case setWishList([Wish])
        case setViewType(ViewType)
        case presentWishDetail(wish: Wish)
        case fetchHome
    }
    
    struct State {
        var wishList: [Wish] = []
        var viewType: ViewType = .list
        var isEmptyMessageHidden: Bool = true
    }
    
    let initialState = State()
    let fetchHomeViewControllerPublisher = PublishRelay<Void>()
    let presentWishDetailPublisher = PublishRelay<Wish>()
    let endRefreshingPublisher = PublishRelay<Void>()
    private let wishService: WishServiceProtocol
    private let userDefaults: UserDefaultsUtils
    private let category: Category
    
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
        case .viewWillAppear:
            let wishList = self.wishService.fetchAllWishes(category: self.category)
            
            return .concat([
                .just(.setWishList(wishList)),
                .just(.setViewType(self.userDefaults.getViewType()))
            ])
            
        case .setViewType(let viewType):
            return .just(.setViewType(viewType))
            
        case .tapWish(let index):
            let tappedWish = self.currentState.wishList[index]
            
            return .just(.presentWishDetail(wish: tappedWish))
            
        case .tapFinishButton(let index):
            let tappedWish = self.currentState.wishList[index]
            
            self.wishService.finishWish(id: tappedWish.id)
            self.cancelNotification(wish: tappedWish)
            
            let wishList = self.wishService.fetchAllWishes(category: self.category)
            
            return .concat([
                .just(.setWishList(wishList)),
                .just(.fetchHome)
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setWishList(let wishList):
            newState.wishList = wishList
            newState.isEmptyMessageHidden = !wishList.isEmpty
            self.endRefreshingPublisher.accept(())
            
        case .setViewType(let viewType):
            newState.viewType = viewType
            
        case .presentWishDetail(let wish):
            self.presentWishDetailPublisher.accept(wish)
            
        case .fetchHome:
            self.fetchHomeViewControllerPublisher.accept(())
        }
        
        return newState
    }
    
    private func cancelNotification(wish: Wish) {
        NotificationManager.shared.cancel(wish: wish)
    }
}
