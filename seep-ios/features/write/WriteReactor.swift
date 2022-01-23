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
        case addNotifictaion(SeepNotification)
        case updateNotification(Int, SeepNotification)
        case deleteNotification(Int)
        case setNotificationEnable(Bool)
        case pushNotificationDetail([SeepNotification], Int?)
        case setMemo(String)
        case setHashtag(String)
        case setWriteButtonState(WriteButton.WriteButtonState)
        case dismiss
    }
    
    struct State {
        var isTooltipShown: Bool
        var emoji: String = ""
        var category: Category
        var title: String = ""
        var titleError: String? = nil
        var deadline: Date? = nil
        var deadlineError: String? = nil
        var deadlineEnable = true
        var notifications: [SeepNotification] = [SeepNotification()]
        var isNotificationEnable = true
        var memo: String = ""
        var hashtags: [HashtagType] = HashtagType.array
        var selectedHahstagIndex: Int?
        var customHashtag: String = ""
        var writeButtonState: WriteButton.WriteButtonState = .initial
    }
    
    let initialState: State
    let pushNotificationPublisher = PublishRelay<([SeepNotification], Int?)>()
    let dismissPublisher = PublishRelay<Void>()
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
            return .just(.setDeadline(date))
            
        case .tapDeadlineSwitch(let isEnable):
            return .just(.setDeadlineEnable(isEnable))
            
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
            return .empty()
            
        case .inputHashtag(let hashtag):
            return .just(.setHashtag(hashtag))
            
        case .tapWriteButton:
            return .empty()
//            var observables: [Observable<Mutation>] = []
//            if self.currentState.title.isEmpty {
//                observables.append(.just(.setTitleError("write_error_title_empty".localized)))
//            }
//            if self.currentState.notifications == nil {
//                observables.append(.just(.setDateError("write_error_date_empty".localized)))
//            }
//
//            if observables.isEmpty {
//                let wish = Wish().then {
//                    $0.emoji = self.currentState.emoji.isEmpty ? self.generateRandomEmoji() : self.currentState.emoji
//                    $0.category = self.currentState.category.rawValue
//                    $0.title = self.currentState.title
//                    $0.date = self.currentState.notificationDates ?? Date()
//                    $0.isPushEnable = self.currentState.isPushEnable
//                    $0.memo = self.currentState.memo
//                    $0.hashtag = self.currentState.hashtag
//                }
//                self.wishService.addWish(wish: wish)
//
//                if self.currentState.isNotificationEnable {
//                    NotificationManager.shared.reserve(wish: wish)
//                }
//                observables.append(.just(.saveWish(())))
//            }
//
//            return .concat(observables)
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
            newState.deadlineEnable = isEnable
            
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
            
        case .setHashtag(let hashtag):
            newState.customHashtag = hashtag
            
        case .setWriteButtonState(let state):
            newState.writeButtonState = state
            
        case .dismiss:
            self.dismissPublisher.accept(())
        }
        
        return newState
    }
    
    private func validateForEnable(title: String) -> WriteButton.WriteButtonState {
        return title.isEmpty ? .initial : .active
    }
}
