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
        case inputMemo(String)
        case updateSteps([WishStep])
        case inputTargetAmount(Int)
        case inputLink(WishLinkInput)
        case inputPlace(WishPlace?)
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
        case setSteps([WishStep])
        case setTargetAmount(Int)
        case setLink(WishLinkInput)
        case setPlace(WishPlace?)
        case selectHashtag(index: Int?)
        case setCustomHashtag(String)
        case setWriteButtonState(WriteButton.WriteButtonState)
        case dismissWishCategory(Category)
        case showToast(String)
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
        /// 작성 중인 단계. 작성 완료 때 위시와 함께 저장된다 (GH-5 R-14).
        var steps: [WishStep] = []
        /// 목표 금액(원). 갖고 싶어요일 때만 저장한다 (GH-16 R-1)
        var targetAmount: Int = 0
        /// 링크 칸 값. 갖고 싶어요일 때만 저장하고, 형식이 아니면 작성을 막는다 (GH-29 R-1, R-2)
        var link: WishLinkInput = .empty
        /// 붙인 장소. 가고 싶어요일 때만 저장한다 (GH-31 R-1)
        var place: WishPlace?
        var hashtags: [HashtagType] = HashtagType.array
        var selectedHashtag: HashtagType?
        var customHashtag: String = ""
        var writeButtonState: WriteButton.WriteButtonState = .initial
    }
    
    let initialState: State
    let pushNotificationPublisher = PublishRelay<([SeepNotification], Int?)>()
    let dismissWishCategoryPublisher = PublishRelay<Category>()
    let showToastPublisher = PublishRelay<String>()
    private let wishService: WishServiceProtocol
    private let userDefaults: UserDefaultsUtils
    private let notificationManager: NotificationManagerProtocol
    private let logManager: LogManagerProtocol
    
    init(
        category: Category,
        wishService: WishServiceProtocol,
        userDefaults: UserDefaultsUtils,
        notificationManager: NotificationManagerProtocol,
        logManager: LogManagerProtocol = LogManager.shared
    ) {
        self.initialState = State(
            isTooltipShown: userDefaults.getRandomEmojiTooltipIsShow(),
            category: category
        )
        self.wishService = wishService
        self.userDefaults = userDefaults
        self.notificationManager = notificationManager
        self.logManager = logManager
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .tooltipDisappeared:
            self.userDefaults.setRandomEmojiTooltipIsShow(isShown: true)
            
            return .just(.setTooltipShown(true))
            
        case .inputEmoji(let emoji):
            return .just(.setEmoji(emoji))
            
        case .tapCategory(let category):
            return .merge([
                .just(.setCategory(category)),
                .just(.setWriteButtonState(self.validateForEnable(category: category)))
            ])
            
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

        case .updateSteps(let steps):
            return .just(.setSteps(steps))

        case .inputTargetAmount(let amount):
            return .just(.setTargetAmount(min(max(amount, 0), WishSaving.maxAmount)))
            
        case .inputLink(let link):
            return .merge([
                .just(.setLink(link)),
                .just(.setWriteButtonState(self.validateForEnable(link: link)))
            ])
            
        case .inputPlace(let place):
            return .just(.setPlace(place))
            
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
            
        case .tapWriteButton:
            var observables: [Observable<Mutation>] = []
            
            if self.currentState.title.isEmpty {
                observables.append(.just(.setTitleError("write_error_title_empty".localized)))
            }
            
            if self.currentState.isDeadlineEnable && self.currentState.deadline == nil {
                observables.append(.just(.setDeadlineError("write_error_date_empty".localized)))
            }
            
            // 링크 형식 안내는 링크 칸이 이미 보여준다 (GH-29 R-2)
            let isLinkBlocking = self.currentState.link.blocksSave(category: self.currentState.category)
            
            if observables.isEmpty && !isLinkBlocking {
                return self.writeWish()
            } else {
                return .merge(observables)
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

        case .setSteps(let steps):
            newState.steps = steps

        case .setTargetAmount(let amount):
            newState.targetAmount = amount
            
        case .setLink(let link):
            newState.link = link
            
        case .setPlace(let place):
            newState.place = place
            
        case .selectHashtag(let index):
            if let index = index {
                newState.selectedHashtag = newState.hashtags[index]
            } else {
                newState.selectedHashtag = nil
            }
            
        case .setCustomHashtag(let hashtag):
            newState.customHashtag = hashtag
            
        case .setWriteButtonState(let state):
            newState.writeButtonState = state
            
        case .dismissWishCategory(let category):
            self.dismissWishCategoryPublisher.accept(category)
            
        case .showToast(let message):
            self.showToastPublisher.accept(message)
        }
        
        return newState
    }
    
    private func validateForEnable(
        title: String? = nil,
        category: Category? = nil,
        link: WishLinkInput? = nil
    ) -> WriteButton.WriteButtonState {
        let title = title ?? self.currentState.title
        let category = category ?? self.currentState.category
        let link = link ?? self.currentState.link
        return (title.isEmpty || link.blocksSave(category: category)) ? .initial : .active
    }
    
    private func writeWish() -> Observable<Mutation> {
        var hashtag = ""
        
        if let selectedHashtag = self.currentState.selectedHashtag {
            hashtag = selectedHashtag.rawValue
        }
        if !self.currentState.customHashtag.isEmpty {
            hashtag = self.currentState.customHashtag
        }

        let wish = Wish(
            emoji: self.currentState.emoji.isEmpty ? self.generateRandomEmoji() : self.currentState.emoji,
            category: self.currentState.category,
            title: self.currentState.title,
            endDate: self.currentState.isDeadlineEnable
                ? self.currentState.deadline
                : nil,
            notifications: self.currentState.isNotificationEnable
                ? self.currentState.notifications
                : [],
            steps: self.currentState.steps,
            // 다른 카테고리로 바꿨으면 입력했던 목표 금액은 버린다 (GH-16 R-1)
            targetAmount: self.currentState.category == .wantToGet ? self.currentState.targetAmount : 0,
            memo: self.currentState.memo,
            hashtag: hashtag,
            // 다른 카테고리로 바꿨으면 링크도 버린다 (GH-29 R-1)
            link: self.currentState.link.storedLink(category: self.currentState.category),
            // 다른 카테고리로 바꿨으면 골랐던 장소는 버린다 (GH-31 R-1)
            place: self.currentState.category == .wantToGo ? self.currentState.place : nil
        )
        
        self.wishService.addWish(wish: wish)
        self.notificationManager.reserveNotifications(wish: wish)
        self.logManager.sendEvent(event: ClickEvent(
            screen: .write,
            objectType: .button,
            objectId: .write,
            extraParameters: [.hasTargetAmount: wish.targetAmount > 0]
        ))
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
