import RxSwift
import RxCocoa
import ReactorKit

class PageItemReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
  }
  
  enum Mutation {
    case fetchWishList([Wish])
    case setViewType(ViewType)
  }
  
  struct State {
    var wishiList: [Wish] = []
    var viewType: ViewType = .list
    var endRefresh: Bool = false
  }
  
  let initialState = State()
  let wishService: WishServiceProtocol
  let userDefaults: UserDefaultsUtils
  let category: Category
  
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
    case .viewDidLoad():
      let wishList = self.wishService.fetchAllWishes(category: self.category)
      
      return Observable.concat([
        Observable.just(Mutation.fetchWishList(wishList)),
        Observable.just(Mutation.setViewType(self.userDefaults.getViewType()))
      ])
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .fetchWishList(let wishList):
      newState.wishiList = wishList
      newState.endRefresh.toggle()
    case .setViewType(let viewType):
      newState.viewType = viewType
    }
    
    return newState
  }
}
