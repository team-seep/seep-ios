import RxSwift
import ReactorKit

class WriteReactor: Reactor {
  
  enum Action {
    case viewDidLoad(Void)
    case tooltipDisappeared
    case inputEmoji(String)
    case tapCategory(Category)
    case tapRandomEmoji(Void)
    case inputTitle(String)
    case inputDate(Date)
    case tapPushButton(Void)
    case inputMemo(String)
    case inputHashtag(String)
    case tapWriteButton(Void)
  }
  
  enum Mutation {
    case setTooltipShown(Bool)
    case fetchDescription(Int)
    case setEmoji(String)
    case setCategory(Category)
    case setTitle(String)
    case setTitleError(String?)
    case setDate(Date)
    case setDateError(String?)
    case togglePushEnable(Void)
    case setMemo(String)
    case setHashtag(String)
    case saveWish(Void)
  }
  
  struct State {
    var isTooltipShown: Bool
    var descriptionIndex: Int = 1
    var emoji: String = ""
    var category: Category
    var title: String = ""
    var titleError: String? = nil
    var date: Date?
    var dateError: String? = nil
    var isPushEnable: Bool = false
    var isPushButtonVisible: Bool = false
    var memo: String = ""
    var hashtag: String = ""
    var writeButtonState: WriteButton.WriteButtonState = .initial
    var shouldDismiss: Bool = false
  }
  
  let initialState: State
  let wishService: WishServiceProtocol
  let userDefaults: UserDefaultsUtils
  
  
  init(
    category: Category,
    wishService: WishServiceProtocol,
    userDefaults: UserDefaultsUtils
  ) {
    self.initialState = State(
      isTooltipShown: userDefaults.getRandomEmojiTooltipIsShow(),
      category: category
    )
    self.wishService = wishService
    self.userDefaults = userDefaults
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .viewDidLoad():
      return Observable.just(Mutation.fetchDescription(1))
    case .tooltipDisappeared:
      self.userDefaults.setRandomEmojiTooltipIsShow(isShown: true)
      
      return .just(.setTooltipShown(true))
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
    case .tapWriteButton():
      var observables: [Observable<Mutation>] = []
      if self.currentState.title.isEmpty {
        observables.append(.just(.setTitleError("write_error_title_empty".localized)))
      }
      if self.currentState.date == nil {
        observables.append(.just(.setDateError("write_error_date_empty".localized)))
      }
      
      if observables.isEmpty {
        let wish = Wish().then {
          $0.emoji = self.currentState.emoji.isEmpty ? self.generateRandomEmoji() : self.currentState.emoji
          $0.category = self.currentState.category.rawValue
          $0.title = self.currentState.title
          $0.date = self.currentState.date ?? Date()
          $0.isPushEnable = self.currentState.isPushEnable
          $0.memo = self.currentState.memo
          $0.hashtag = self.currentState.hashtag
        }
        self.wishService.addWish(wish: wish)
        
        if self.currentState.isPushEnable {
          NotificationManager.shared.reserve(wish: wish)
        }
        observables.append(.just(.saveWish(())))
      }
      
      return .concat(observables)
    }
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setTooltipShown(let isShown):
      newState.isTooltipShown = isShown
    case .fetchDescription(let index):
      newState.descriptionIndex = index
    case .setEmoji(let emoji):
      newState.emoji = emoji
    case .setCategory(let category):
      newState.category = category
    case .setTitle(let title):
      newState.title = title
      newState.writeButtonState = self.validateForEnable(state: newState)
    case .setTitleError(let errorMessage):
      newState.titleError = errorMessage
    case .setDate(let date):
      newState.date = date
      newState.isPushButtonVisible = true
      newState.writeButtonState = self.validateForEnable(state: newState)
    case .setDateError(let errorMessage):
      newState.dateError = errorMessage
    case .togglePushEnable():
      newState.isPushEnable = !state.isPushEnable
    case .setMemo(let memo):
      newState.memo = memo
    case .setHashtag(let hashtag):
      newState.hashtag = hashtag
    case .saveWish():
      newState.shouldDismiss = true
    }
    
    return newState
  }
  
  private func validateForEnable(state: State) -> WriteButton.WriteButtonState {
    if state.title.isEmpty && state.date == nil {
      return .initial
    } else if !state.title.isEmpty && (state.date != nil) {
      return .active
    } else {
      return .more
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
