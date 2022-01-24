import Foundation

import RxSwift
import ReactorKit
import RxRelay

class WriteReactor: Reactor {
    enum Action {
        case tooltipDisappeared
        case inputEmoji(String)
        case tapCategory(Category)
        case inputTitle(String)
        case inputDeadline(Date)
        case tapDeadlineSwitch(Bool)
        case addNotification(SeepNotification)
        case tapAddNotificationButton
        case tapEditNotification(index: Int)
        case updateNotification(index: Int, notification: SeepNotification)
        case deleteNotification(index: Int)
        case tapNotificationSwitch(Bool)
        case tapNotification(index: Int)
        case inputMemo(String)
        case tapHashtag(index: Int)
        case inputHashtag(String)
        case tapWriteButton
    }
    
    enum Mutation {
        case setTooltipShown(Bool)
        case setEmoji(String)
        case setCategory(Category)
        case setTitle(String)
        case setTitleError(String?)
        case setDeadline(Date)
        case setDeadlineEnable(Bool)
        case setDeadlineError(String?)
        case addNotifictaion(SeepNotification)
        case updateNotification(Int, SeepNotification)
        case deleteNotification(Int)
        case setNotificationEnable(Bool)
        case pushNotificationDetail([SeepNotification], Int?)
        case setMemo(String)
        case selectHashtag(index: Int)
        case setCustomHashtag(String)
        case setWriteButtonState(WriteButton.WriteButtonState)
        case dismissWishCategory(Category)
    }
    
    struct State {
        var isTooltipShown: Bool
        var emoji: String = ""
        var category: Category
        var title: String = ""
        var titleError: String? = nil
        var deadline: Date? = nil
        var deadlineError: String? = nil
        var isDeadlineEnable = true
        var notifications: [SeepNotification] = [SeepNotification()]
        var isNotificationEnable = true
        var memo: String = ""
        var hashtags: [HashtagType] = HashtagType.array
        var selectedHashtag: HashtagType?
        var customHashtag: String = ""
        var writeButtonState: WriteButton.WriteButtonState = .initial
    }
    
    let initialState: State
    let pushNotificationPublisher = PublishRelay<([SeepNotification], Int?)>()
    let dismissWishCategoryPublisher = PublishRelay<Category>()
    private let wishService: WishServiceProtocol
    private let userDefaults: UserDefaultsUtils
    
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
        case .tooltipDisappeared:
            self.userDefaults.setRandomEmojiTooltipIsShow(isShown: true)
            
            return .just(.setTooltipShown(true))
            
        case .inputEmoji(let emoji):
            return .just(.setEmoji(emoji))
            
        case .tapCategory(let category):
            return .just(.setCategory(category))
            
        case .inputTitle(let title):
            return .merge([
                .just(.setTitle(title)),
                .just(.setTitleError(nil)),
                .just(.setWriteButtonState(self.validateForEnable(title: title)))
            ])
            
        case .inputDeadline(let date):
            return .merge([
                .just(.setDeadline(date)),
                .just(.setDeadlineError(nil))
            ])
            
        case .tapDeadlineSwitch(let isEnable):
            return .merge([
                .just(.setDeadlineEnable(isEnable)),
                .just(.setDeadlineError(nil))
            ])
            
        case .addNotification(let notification):
            return .just(.addNotifictaion(notification))
            
        case .tapAddNotificationButton:
            return .just(.pushNotificationDetail(self.currentState.notifications, nil))
            
        case .tapEditNotification(let index):
            return .just(.pushNotificationDetail(self.currentState.notifications, index))
            
        case .updateNotification(let index, let notification):
            return .just(.updateNotification(index, notification))
            
        case .deleteNotification(let index):
            return .just(.deleteNotification(index))
            
        case .tapNotificationSwitch(let isEnable):
            return .just(.setNotificationEnable(isEnable))
            
        case .tapNotification(let index):
            return .just(.pushNotificationDetail(
                self.currentState.notifications,
                index
            ))
            
        case .inputMemo(let memo):
            return .just(.setMemo(memo))
            
        case .tapHashtag(let index):
            return .just(.selectHashtag(index: index))
            
        case .inputHashtag(let hashtag):
            return .just(.setCustomHashtag(hashtag))
            
        case .tapWriteButton:
            var observables: [Observable<Mutation>] = []
            
            if self.currentState.title.isEmpty {
                observables.append(.just(.setTitleError("write_error_title_empty".localized)))
            }
            
            if self.currentState.isDeadlineEnable && self.currentState.deadline == nil {
                observables.append(.just(.setDeadlineError("write_error_date_empty".localized)))
            }
            
            if observables.isEmpty {
                return self.writeWish()
            } else {
                return .concat(observables)
            }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setTooltipShown(let isShown):
            newState.isTooltipShown = isShown
            
        case .setEmoji(let emoji):
            newState.emoji = emoji
            
        case .setCategory(let category):
            newState.category = category
            
        case .setTitle(let title):
            newState.title = title
            
        case .setTitleError(let errorMessage):
            newState.titleError = errorMessage
            
        case .setDeadline(let date):
            newState.deadline = date
            
        case .setDeadlineEnable(let isEnable):
            newState.isDeadlineEnable = isEnable
            
        case .setDeadlineError(let errorMessage):
            newState.deadlineError = errorMessage
            
        case .addNotifictaion(let notification):
            newState.notifications.append(notification)
            
        case .updateNotification(let index, let notification):
            newState.notifications[index] = notification
            
        case .deleteNotification(let index):
            newState.notifications.remove(at: index)
            
        case .setNotificationEnable(let isEnable):
            newState.isNotificationEnable = isEnable
            
        case .pushNotificationDetail(let notifications, let index):
            self.pushNotificationPublisher.accept((notifications, index))
            
        case .setMemo(let memo):
            newState.memo = memo
            
        case .selectHashtag(let index):
            newState.selectedHashtag = newState.hashtags[index]
            
        case .setCustomHashtag(let hashtag):
            newState.customHashtag = hashtag
            
        case .setWriteButtonState(let state):
            newState.writeButtonState = state
            
        case .dismissWishCategory(let category):
            self.dismissWishCategoryPublisher.accept(category)
        }
        
        return newState
    }
    
    private func validateForEnable(title: String) -> WriteButton.WriteButtonState {
        return title.isEmpty ? .initial : .active
    }
    
    private func writeWish() -> Observable<Mutation> {
        var hashtags: [String] = []

        if let selectedHashtag = self.currentState.selectedHashtag {
            hashtags.append(selectedHashtag.description)
        }

        if !self.currentState.customHashtag.isEmpty {
            hashtags.append(self.currentState.customHashtag)
        }

        let wish = Wish(
            emoji: self.currentState.emoji.isEmpty ? self.generateRandomEmoji() : self.currentState.emoji,
            category: self.currentState.category,
            title: self.currentState.title,
            endDate: self.currentState.deadline,
            notifications: self.currentState.notifications,
            memo: self.currentState.memo,
            hashtags: hashtags
        )
        
        self.wishService.addWish(wish: wish)
        // TODO: 알림 설정 필요
//        NotificationManager.shared.reserve(wish: wish)
        return .just(.dismissWishCategory(wish.category))
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
