import RxSwift
import RxCocoa
import ReactorKit

class FinishedReactor: Reactor {
  
  enum Action {
    case viewDidLoad
    case tapViewType
  }
  
  enum Mutation {
    case fetchFinishedWishList([Wish])
    case setViewType(ViewType)
    case setEmptyViewHidden(Bool)
  }
  
  struct State {
    var finishedWishiList: [Wish] = []
    var finishedCount: Int = 0
    var isHiddenEmptyView: Bool = false
    var viewType: ViewType = .list
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
    case .viewDidLoad:
      let finishedWishList = self.wishService.fetchFinishedWishes(category: self.category)
      
      return Observable.concat([
        Observable.just(Mutation.fetchFinishedWishList(finishedWishList)),
        Observable.just(Mutation.setViewType(self.userDefaults.getViewType())),
        Observable.just(Mutation.setEmptyViewHidden(!finishedWishList.isEmpty))
      ])
    case .tapViewType:
      return Observable.just(Mutation.setViewType(self.currentState.viewType.toggle()))
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
    }
    
    return newState
  }

}
