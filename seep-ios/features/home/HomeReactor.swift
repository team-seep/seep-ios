import RxSwift
import RxCocoa
import ReactorKit

class HomeReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
    case tapCategory(Category)
    case tapViewType(Void)
  }
  
  enum Mutation {
    case filterCategory(Category)
    case setViewType(ViewType)
    case setSuccessCount(Int)
    case setWishCount(Int)
    case setWriteButtonTitle(String)
  }
  
  struct State {
    var wishCount: Int = 0
    var successCount: Int = 0
    var category: Category = .wantToDo
    var viewType: ViewType = .list
    var writeButtonTitle: String = "home_write_category_want_to_do_button".localized
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
      let successCount = self.wishService.getFinishCount()
      let wishCount = self.wishService.getWishCount(category: self.currentState.category)
      
      return Observable.concat([
        Observable.just(Mutation.setWishCount(wishCount)),
        Observable.just(Mutation.setSuccessCount(successCount)),
        Observable.just(Mutation.setViewType(self.userDefaults.getViewType()))
      ])
    case .tapCategory(let category):
      let wishCount = self.wishService.getWishCount(category: category)
      let writeButtonTitle = "home_write_\(category.rawValue)_button".localized
      
      return Observable.concat([
        Observable.just(Mutation.setWishCount(wishCount)),
        Observable.just(Mutation.filterCategory(category)),
        Observable.just(Mutation.setWriteButtonTitle(writeButtonTitle))
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
    case .filterCategory(let category):
      newState.category = category
    case .setSuccessCount(let count):
      newState.successCount = count
    case .setWishCount(let count):
      newState.wishCount = count
    case .setViewType(let viewType):
      newState.viewType = viewType
    case .setWriteButtonTitle(let title):
      newState.writeButtonTitle = title
    }
    
    return newState
  }
}
