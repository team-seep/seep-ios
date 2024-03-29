import Foundation

import RxSwift
import RxCocoa
import ReactorKit

final class WishEditReactor: Reactor {
    enum Action {
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
        case inputMemo(String)
        case tapHashtag(index: Int)
        case inputHashtag(String)
        case tapEditButton
    }
    
    enum Mutation {
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
        case selectHashtag(index: Int?)
        case setCustomHashtag(String)
        case setEditButtonState(EditButton.EditButtonState)
        case popupWishWish(Wish)
        case showToast(String)
    }
    
    struct State {
        var emoji: String
        var category: Category
        var title: String
        var titleError: String? = nil
        var deadline: Date?
        var deadlineError: String? = nil
        var isDeadlineEnable: Bool
        var notifications: [SeepNotification]
        var isNotificationEnable: Bool
        var memo: String
        var hashtags: [HashtagType] = HashtagType.array
        var selectedHashtag: HashtagType?
        var customHashtag: String
        var editButtonState: EditButton.EditButtonState = .active
    }
    
    let initialState: State
    let pushNotificationPublisher = PublishRelay<([SeepNotification], Int?)>()
    let popupWithWishPublisher = PublishRelay<Wish>()
    let showToastPublisher = PublishRelay<String>()
    private let wishID: String
    private let wishService: WishServiceProtocol
    private let notificationManager: NotificationManagerProtocol
    
    init(
        wish: Wish,
        wishService: WishServiceProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.initialState = State(
            emoji: wish.emoji,
            category: wish.category,
            title: wish.title,
            deadline: wish.endDate,
            isDeadlineEnable: wish.endDate != nil,
            notifications: wish.notifications.isEmpty ? [SeepNotification()] : wish.notifications,
            isNotificationEnable: !wish.notifications.isEmpty,
            memo: wish.memo,
            selectedHashtag: HashtagType(rawValue: wish.hashtag),
            customHashtag: HashtagType(rawValue: wish.hashtag) == nil ? wish.hashtag : ""
        )
        self.wishID = wish.id
        self.wishService = wishService
        self.notificationManager = notificationManager
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .inputEmoji(let emoji):
            return .just(.setEmoji(emoji))
            
        case .tapCategory(let category):
            return .just(.setCategory(category))
            
        case .inputTitle(let title):
            return .merge([
                .just(.setTitle(title)),
                .just(.setTitleError(nil)),
                .just(.setEditButtonState(self.validateForEnable(title: title)))
            ])
            
        case .inputDeadline(let date):
            return .merge([
                .just(.setDeadline(date)),
                .just(.setDeadlineError(nil))
            ])
            
        case .tapDeadlineSwitch(let isEnable):
            return .merge([
                .just(.setDeadlineEnable(isEnable)),
                .just(.setDeadlineError(nil)),
                .just(.setNotificationEnable(isEnable))
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
            if !self.currentState.isDeadlineEnable {
                return .merge([
                    .just(.setNotificationEnable(!isEnable)),
                    .just(.showToast("알림 허용을 위해선 날짜 지정이 필요해요."))
                ])
            } else {
                return .just(.setNotificationEnable(isEnable))
            }
            
        case .inputMemo(let memo):
            return .just(.setMemo(memo))
            
        case .tapHashtag(let index):
            return .merge([
                .just(.setCustomHashtag("")),
                .just(.selectHashtag(index: index))
            ])
            
        case .inputHashtag(let hashtag):
            return .merge([
                .just(.selectHashtag(index: nil)),
                .just(.setCustomHashtag(hashtag))
            ])
            
        case .tapEditButton:
            var observables: [Observable<Mutation>] = []
            
            if self.currentState.title.isEmpty {
                observables.append(.just(.setTitleError("write_error_title_empty".localized)))
            }
            
            if self.currentState.isDeadlineEnable && self.currentState.deadline == nil {
                observables.append(.just(.setDeadlineError("write_error_date_empty".localized)))
            }
            
            if observables.isEmpty {
                return self.updateWish()
            } else {
                return .merge(observables)
            }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
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
            if let index = index {
                newState.selectedHashtag = newState.hashtags[index]
            } else {
                newState.selectedHashtag = nil
            }
            
        case .setCustomHashtag(let hashtag):
            newState.customHashtag = hashtag
            
        case .setEditButtonState(let state):
            newState.editButtonState = state
            
        case .popupWishWish(let wish):
            self.popupWithWishPublisher.accept(wish)
            
        case .showToast(let message):
            self.showToastPublisher.accept(message)
        }
        
        return newState
    }
    
    private func validateForEnable(title: String) -> EditButton.EditButtonState {
        return title.isEmpty ? .more : .active
    }
    
    private func updateWish() -> Observable<Mutation> {
        var hashtag = ""
        
        if let selectedHashtag = self.currentState.selectedHashtag {
            hashtag = selectedHashtag.rawValue
        }
        if !self.currentState.customHashtag.isEmpty {
            hashtag = self.currentState.customHashtag
        }

        let wish = Wish(
            id: self.wishID,
            emoji: self.currentState.emoji.isEmpty ? self.generateRandomEmoji() : self.currentState.emoji,
            category: self.currentState.category,
            title: self.currentState.title,
            endDate: self.currentState.isDeadlineEnable
                ? self.currentState.deadline
                : nil,
            notifications: self.currentState.isNotificationEnable
                ? self.currentState.notifications
                : [],
            memo: self.currentState.memo,
            hashtag: hashtag
        )
        
        self.wishService.updateWish(id: self.wishID, newWish: wish)
        self.notificationManager.cancelNotifications(wish: wish)
        self.notificationManager.reserveNotifications(wish: wish)
        return .just(.popupWishWish(wish))
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
