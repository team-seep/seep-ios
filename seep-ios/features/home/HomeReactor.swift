import RxSwift
import RxCocoa
import ReactorKit

class HomeReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
    case tapCategory(Category)
    case tapViewType(Void)
//    case tapItem(Int)
  }
  
  enum Mutation {
    case fetchWishList([Wish])
    case filterCategory(Category)
    case setViewType(ViewType)
    case setSuccessCount(Int)
  }
  
  struct State {
    var wishiList: [Wish] = []
    var successCount: Int = 0
    var category: Category = .wantToDo
    var viewType: ViewType = .list
    var endRefresh: Bool = false
  }
  
  let initialState = State()
  let wishService: WishServiceProtocol
  let userDefaults: UserDefaultsUtils
  
  
  init(wishService: WishServiceProtocol, userDefaults: UserDefaultsUtils) {
    self.wishService = wishService
    self.userDefaults = userDefaults
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .viewDidLoad():
      let wishList = self.wishService.fetchAllWishes(category: self.initialState.category)
      let successCount = self.wishService.getFinishCount()
      
      return Observable.concat([
        Observable.just(Mutation.fetchWishList(wishList)),
        Observable.just(Mutation.setSuccessCount(successCount)),
        Observable.just(Mutation.setViewType(self.userDefaults.getViewType()))
      ])
    case .tapCategory(let category):
      let filterWishList = self.wishService.fetchAllWishes(category: category)
      
      return Observable.concat([
        Observable.just(Mutation.fetchWishList(filterWishList)),
        Observable.just(Mutation.filterCategory(category))
      ])
    case .tapViewType():
      let viewType = self.currentState.viewType.toggle()
      
      self.userDefaults.setViewType(viewType: viewType)
      return Observable.just(Mutation.setViewType(viewType))
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .fetchWishList(let wishList):
      newState.wishiList = wishList
      newState.endRefresh.toggle()
    case .filterCategory(let category):
      newState.category = category
    case .setSuccessCount(let count):
      newState.successCount = count
    case .setViewType(let viewType):
      newState.viewType = viewType
    }
    
    return newState
  }
}
