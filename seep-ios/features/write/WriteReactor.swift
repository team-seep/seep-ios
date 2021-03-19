import RxSwift
import ReactorKit

class WriteReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
    case inputEmoji(String)
    case tapCategory(Category)
    case inputTitle(String)
    case inputDate(Date)
    case tapPushButton(Void)
    case inputMemo(String)
    case tapWriteButton(Void)
  }
  
  enum Mutation {
    case fetchDescription(Int)
    case setEmoji(String)
    case setCategory(Category)
    case setTitle(String)
    case setDate(Date)
    case togglePushEnable(Void)
    case setMemo(String)
    case saveWish(Void)
  }
  
  struct State {
    var descriptionIndex: Int = 1
    var emoji: String = ""
    var category: Category = .wantToDo
    var title: String = ""
    var date: Date?
    var isPushEnable: Bool = false
    var memo: String = ""
    var writeButtonEnable: Bool = false
    var shouldDismiss: Bool = false
  }
  
  let initialState = State()
  let wishService: WishServiceProtocol
  
  
  init(wishService: WishServiceProtocol) {
    self.wishService = wishService
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .viewDidLoad():
      return Observable.just(Mutation.fetchDescription(1))
    case .inputEmoji(let emoji):
      return Observable.just(Mutation.setEmoji(emoji))
    case .tapCategory(let category):
      return Observable.just(Mutation.setCategory(category))
    case .inputTitle(let title):
      return Observable.just(Mutation.setTitle(title))
    case .inputDate(let date):
      return Observable.just(Mutation.setDate(date))
    case .tapPushButton():
      return Observable.just(Mutation.togglePushEnable(()))
    case .inputMemo(let memo):
      return Observable.just(Mutation.setMemo(memo))
    case .tapWriteButton():
      let wish = Wish().then {
        $0.emoji = self.initialState.emoji
        $0.category = self.initialState.category.rawValue
        $0.title = self.initialState.title
        $0.date = self.initialState.date ?? Date()
        $0.isPushEnable = self.initialState.isPushEnable
        $0.memo = self.initialState.memo
      }
      
      self.wishService.addWish(wish: wish)
      return Observable.just(Mutation.saveWish(()))
    }
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .fetchDescription(let index):
      newState.descriptionIndex = index
    case .setEmoji(let emoji):
      newState.emoji = emoji
      newState.writeButtonEnable = self.validate(state: newState)
    case .setCategory(let category):
      newState.category = category
    case .setTitle(let title):
      newState.title = title
      newState.writeButtonEnable = self.validate(state: newState)
    case .setDate(let date):
      newState.date = date
      newState.writeButtonEnable = self.validate(state: newState)
    case .togglePushEnable():
      newState.isPushEnable = !state.isPushEnable
    case .setMemo(let memo):
      newState.memo = memo
    case .saveWish():
      newState.shouldDismiss = true
    }
    
    return newState
  }
  
  private func validate(state: State) -> Bool {
    return !state.title.isEmpty && (state.date != nil)
  }
}
