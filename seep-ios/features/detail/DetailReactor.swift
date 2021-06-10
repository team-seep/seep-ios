import RxSwift
import ReactorKit

class DetailReactor: Reactor {
  
  enum Action {
    case tapEditButton
    case tapDeleteButton
    case tapCancelButton
    case inputEmoji(String)
    case tapCategory(Category)
    case tapRandomEmojiButton
    case inputTitle(String)
    case inputDate(Date)
    case tapPushButton(Void)
    case inputMemo(String)
    case inputHashtag(String)
    case tapSaveButton
  }
  
  enum Mutation {
    case setEditable(Bool)
    case deleteWish
    case resetWish
    case setEmoji(String)
    case setCategory(Category)
    case setTitle(String)
    case setTitleError(String?)
    case setDate(Date)
    case setDateError(String?)
    case togglePushEnable
    case setMemo(String)
    case setHashtag(String)
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
  var initialWish: Wish
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
    self.initialWish = wish
    self.wishService = wishService
  }
  
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapEditButton:
      return Observable.just(Mutation.setEditable(true))
    case .tapDeleteButton:
      self.wishService.deleteWish(id: self.initialWish._id)
      
      return Observable.just(Mutation.deleteWish)
    case .tapCancelButton:
      return Observable.just(Mutation.resetWish)
    case .inputEmoji(let emoji):
      return Observable.just(Mutation.setEmoji(emoji))
    case .tapCategory(let category):
      return Observable.concat([
        Observable.just(Mutation.setCategory(category)),
        Observable.just(Mutation.setEditable(true))
      ])
    case .tapRandomEmojiButton:
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
      return Observable.concat([
        Observable.just(Mutation.togglePushEnable),
        Observable.just(Mutation.setEditable(true))
      ])
    case .inputMemo(let memo):
      return Observable.just(Mutation.setMemo(memo))
    case .inputHashtag(let hashtag):
      return Observable.just(Mutation.setHashtag(hashtag))
    case .tapSaveButton:
      if self.currentState.title.isEmpty {
        return Observable.just(Mutation.setTitleError("write_error_title_empty".localized))
      } else {
        let wish = Wish().then {
          $0._id = self.initialWish._id
          $0.emoji = self.currentState.emoji.isEmpty ? self.generateRandomEmoji() : self.currentState.emoji
          $0.category = self.currentState.category.rawValue
          $0.title = self.currentState.title
          $0.date = self.currentState.date
          $0.isPushEnable = self.currentState.isPushEnable
          $0.memo = self.currentState.memo
          $0.hashtag = self.currentState.hashtag
        }
        
        self.wishService.updateWish(id: self.initialWish._id, newWish: wish)
        
        NotificationManager.shared.cancel(wish: self.initialWish)
        if self.currentState.isPushEnable {
          NotificationManager.shared.reserve(wish: wish)
        }
        self.initialWish = wish
        return Observable.just(Mutation.setEditable(false))
      }
    }
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setEditable(let isEditable):
      newState.isEditable = isEditable
    case .deleteWish:
      newState.shouldDismiss = true
    case .resetWish:
      newState = self.initialState
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
    case .togglePushEnable:
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
    let emojiArray = [
      0x1f600...0x1f64f,
      0x1f680...0x1f6c5,
      0x1f6cb...0x1f6d2,
      0x1f6e0...0x1f6e5,
      0x1f6f3...0x1f6fa,
      0x1f7e0...0x1f7eb,
      0x1f90d...0x1f93a,
      0x1f93c...0x1f945,
      0x1f947...0x1f971,
      0x1f973...0x1f976,
      0x1f97a...0x1f9a2,
      0x1f9a5...0x1f9aa,
      0x1f9ae...0x1f9ca,
      0x1f9cd...0x1f9ff,
      0x1fa70...0x1fa73,
      0x1fa78...0x1fa7a,
      0x1fa80...0x1fa82,
      0x1fa90...0x1fa95,
    ].reduce([], +).map { return UnicodeScalar($0)! }
    guard let scalar = emojiArray.randomElement() else { return "❓" }
    
    return String(scalar)
  }
}
