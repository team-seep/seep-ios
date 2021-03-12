import RxSwift
import RxCocoa
import ReactorKit

class HomeReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
    case tapCategory(Category)
    case tapViewType(ViewType)
    case tapItem(Int)
  }
  
  enum Mutation {
    case fetchWishList([String])
  }
  
  struct State {
    var wishiList: [String] = []
    var category: Category = .wantToDo
    var viewTYpe: ViewType = .list
  }
  
  let initialState = State()
  
  
//  func mutate(action: Action) -> Observable<Mutation> {
//
//  }
//
//  func reduce(state: State, mutation: Mutation) -> State {
//
//  }
}
