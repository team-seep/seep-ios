import RxSwift
import RxCocoa
import ReactorKit

class HomeReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
    case tapCategory(Category)
//    case tapViewType(ViewType)
//    case tapItem(Int)
  }
  
  enum Mutation {
    case fetchWishList([Wish])
    case filterCategory(Category)
    case setSuccessCount(Int)
  }
  
  struct State {
    var wishiList: [Wish] = []
    var successCount: Int = 0
    var category: Category = .wantToDo
    var viewTYpe: ViewType = .list
  }
  
  let initialState = State()
  let wishService: WishServiceProtocol
  
  
  init(wishService: WishServiceProtocol) {
    self.wishService = wishService
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .viewDidLoad():
      let wishList = self.wishService.fetchAllWishes(category: self.initialState.category)
      let successCount = self.wishService.getFinishCount()
      
      return Observable.concat([
        Observable.just(Mutation.fetchWishList(wishList)),
        Observable.just(Mutation.setSuccessCount(successCount))
      ])
    case .tapCategory(let category):
      let filterWishList = self.wishService.fetchAllWishes(category: category)
      
      return Observable.concat([
        Observable.just(Mutation.fetchWishList(filterWishList)),
        Observable.just(Mutation.filterCategory(category))
      ])
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .fetchWishList(let wishList):
      newState.wishiList = wishList
    case .filterCategory(let category):
      newState.category = category
    case .setSuccessCount(let count):
      newState.successCount = count
    }
    
    return newState
  }
}
