import RxSwift
import ReactorKit

class DetailReactor: Reactor {
  
  enum Action {
    case inputTitle(String)
  }
  
  enum Mutation {
    case setTitle(String)
  }
  
  struct State {
    var isEditable: Bool = false
    var emoji: String
    var category: Category
    var title: String
    var titleError: String? = nil
    var date: Date
    var dateError: String? = nil
    var isPushEnable: Bool
    var memo: String
    var hashtag: String
  }
  
  let initialState: State
  let wishService: WishServiceProtocol
  
  
  init(wish: Wish, wishService: WishServiceProtocol) {
    self.initialState = State(
      emoji: wish.emoji,
      category: Category(rawValue: wish.category) ?? .wantToDo,
      title: wish.title,
      date: wish.date,
      isPushEnable: wish.isPushEnable,
      memo: wish.memo,
      hashtag: wish.hashtag
    )
    self.wishService = wishService
  }
  
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case.inputTitle(let title):
      return Observable.just(Mutation.setTitle(title))
    }
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setTitle(let title):
      newState.title = title
    }
    return newState
  }
}
