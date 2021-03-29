import RxSwift
import ReactorKit

class DetailReactor: Reactor {
  
  enum Action {
    case inputEmoji(String)
    case tapCategory(Category)
    case tapRandomEmoji(Void)
    case inputTitle(String)
    case inputDate(Date)
    case tapPushButton(Void)
    case inputMemo(String)
    case inputHashtag(String)
    case tapEditButton(Void)
  }
  
  enum Mutation {
    case setEmoji(String)
    case setCategory(Category)
    case setTitle(String)
    case setTitleError(String?)
    case setDate(Date)
    case setDateError(String?)
    case togglePushEnable(Void)
    case setMemo(String)
    case setHashtag(String)
    case setEditable(Void)
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
    var editButtonState: EditButton.EditButtonState = .active
    var shouldDismiss: Bool = false
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
    case .inputEmoji(let emoji):
      return Observable.just(Mutation.setEmoji(emoji))
    case .tapCategory(let category):
      return Observable.just(Mutation.setCategory(category))
    case .tapRandomEmoji():
      let randomEmoji = self.generateRandomEmoji()
      
      return Observable.just(Mutation.setEmoji(randomEmoji))
    case .inputTitle(let title):
      if title.isEmpty {
        return Observable.just(Mutation.setTitle(title))
      } else {
        return Observable.concat([
          Observable.just(Mutation.setTitle(title)),
          Observable.just(Mutation.setTitleError(nil))
        ])
      }
    case .inputDate(let date):
      return Observable.concat([
        Observable.just(Mutation.setDate(date)),
        Observable.just(Mutation.setDateError(nil))
      ])
    case .tapPushButton():
      return Observable.just(Mutation.togglePushEnable(()))
    case .inputMemo(let memo):
      return Observable.just(Mutation.setMemo(memo))
    case .inputHashtag(let hashtag):
      return Observable.just(Mutation.setHashtag(hashtag))
    case .tapEditButton():
      return Observable.just(Mutation.setEditable(()))
    }
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setEditable():
      newState.isEditable = true
    case .setEmoji(let emoji):
      newState.emoji = emoji
    case .setCategory(let category):
      newState.category = category
    case .setTitle(let title):
      newState.title = title
      newState.editButtonState = self.validateForEnable(state: newState)
    case .setTitleError(let errorMessage):
      newState.titleError = errorMessage
      newState.dateError = nil
    case .setDate(let date):
      newState.date = date
      newState.editButtonState = self.validateForEnable(state: newState)
    case .setDateError(let errorMessage):
      newState.dateError = errorMessage
      newState.titleError = nil
    case .togglePushEnable():
      newState.isPushEnable = !state.isPushEnable
    case .setMemo(let memo):
      newState.memo = memo
    case .setHashtag(let hashtag):
      newState.hashtag = hashtag
    }
    
    return newState
  }
  
  private func validateForEnable(state: State) -> EditButton.EditButtonState {
    if state.title.isEmpty {
      return .more
    } else {
      return .active
    }
  }
  
  private func generateRandomEmoji() -> String {
    let range = 0x1F601...0x1F64F
    let randomIndex = Int.random(in: range)
    guard let scalar = UnicodeScalar(randomIndex) else { return "❓" }
    
    return String(scalar)
  }
}
