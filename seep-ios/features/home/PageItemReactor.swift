import RxSwift
import RxCocoa
import ReactorKit

class PageItemReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
    case setViewType(ViewType)
    case tapFinishButton(Int)
    case afterFinish(Void)
  }
  
  enum Mutation {
    case fetchWishList([Wish])
    case setViewType(ViewType)
    case fetchHome(Bool)
  }
  
  struct State {
    var wishiList: [Wish] = []
    var viewType: ViewType = .list
    var endRefresh: Bool = false
    var fetchHomeVC: Bool = false
    var isEmptyMessageHidden: Bool = true
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
    case .setViewType(let viewType):
      return Observable.just(Mutation.setViewType(viewType))
    case .tapFinishButton(let index):
      let tappedWish = self.currentState.wishiList[index]
      self.wishService.finishWish(wish: tappedWish)
      self.cancelNotification(wish: tappedWish)
      let wishList = self.wishService.fetchAllWishes(category: self.category)
      
      return Observable.concat([
        Observable.just(Mutation.fetchWishList(wishList)),
        Observable.just(Mutation.fetchHome(true))
      ])
    case .afterFinish():
      return Observable.just(Mutation.fetchHome(false))
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .fetchWishList(let wishList):
      newState.wishiList = wishList
      newState.isEmptyMessageHidden = !wishList.isEmpty
      newState.endRefresh.toggle()
    case .setViewType(let viewType):
      newState.viewType = viewType
    case .fetchHome(let fetchHome):
      newState.fetchHomeVC = fetchHome
    }
    
    return newState
  }
  
  private func cancelNotification(wish: Wish) {
    NotificationManager.shared.cancel(wish: wish)
  }
}
