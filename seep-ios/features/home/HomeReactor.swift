import Foundation

import RxSwift
import RxCocoa
import ReactorKit

class HomeReactor: Reactor {
  
  enum Action {
    case viewDidLoad
    case tapCategory(Category)
    case tapViewType
  }
  
  enum Mutation {
    case filterCategory(Category)
    case setViewType(ViewType)
    case setSuccessCount(Int)
    case setWishCount(Int)
    case setWriteButtonTitle(String)
    case presentWrite(Category)
  }
  
  struct State {
    var wishCount: Int = 0
    var successCount: Int = 0
    var category: Category = .wantToDo
    var viewType: ViewType = .list
    var writeButtonTitle: String = "home_write_category_want_to_do_button".localized
    var showWrite: Bool = false
  }
  
  let initialState = State()
  let presentWritePublisher = PublishRelay<Category>()
  private let wishService: WishServiceProtocol
  private let userDefaults: UserDefaultsUtils
  
  
  init(wishService: WishServiceProtocol, userDefaults: UserDefaultsUtils) {
    self.wishService = wishService
    self.userDefaults = userDefaults
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .viewDidLoad:
      let successCount = self.wishService.getFinishCount(category: self.currentState.category)
      let wishCount = self.wishService.getWishCount(category: self.currentState.category)
      
      return .merge([
        .just(Mutation.setWishCount(wishCount)),
        .just(Mutation.setSuccessCount(successCount)),
        .just(Mutation.setViewType(self.userDefaults.getViewType())),
        self.handleDeepkLink(urlString: self.userDefaults.getDeepLink())
      ])
    case .tapCategory(let category):
      let wishCount = self.wishService.getWishCount(category: category)
      let successCount = self.wishService.getFinishCount(category: category)
      let writeButtonTitle = "home_write_\(category.rawValue)_button".localized
      
      return Observable.concat([
        Observable.just(Mutation.setWishCount(wishCount)),
        Observable.just(Mutation.setSuccessCount(successCount)),
        Observable.just(Mutation.filterCategory(category)),
        Observable.just(Mutation.setWriteButtonTitle(writeButtonTitle))
      ])
    case .tapViewType:
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
    case let .presentWrite(category):
      self.presentWritePublisher.accept(category)
    }
    
    return newState
  }
  
  private func handleDeepkLink(urlString: String) -> Observable<Mutation> {
    self.userDefaults.setDeepLink(deepLink: "")
    guard !urlString.isEmpty,
          let urlComponents = URLComponents(string: urlString) else {
            return .empty()
          }
    
    if urlComponents.host == "add" {
      if let categoryQuery = urlComponents.queryItems?.first(where: { $0.name == "category" }),
         let category = Category(rawValue: categoryQuery.value ?? "") {
        
        return .just(.presentWrite(category))
      }
    }
    return .empty()
  }
}
