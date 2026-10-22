import Foundation
import Observation

/// 링크 칸 아래 미리보기 (GH-29 R-3)
enum WishFormLinkPreview: Equatable {
    case hidden
    case loading(domain: String)
    case loaded(LinkPreview)
    /// 미리보기를 못 불러왔다. 링크는 그대로 저장할 수 있다
    case failed(domain: String)
}

/// 작성·수정 완료 버튼 모양. 작성은 initial/active, 수정은 more/active (레거시 `WriteButton`·`EditButton`)
enum WishFormSaveButtonState: Equatable {
    case initial
    case more
    case active
}

/// 폼이 띄우는 시트
enum WishFormSheet: Identifiable, Equatable {
    case emoji
    case date
    case notification(NotificationEditorConfig)
    case placeSearch

    var id: String {
        switch self {
        case .emoji: return "emoji"
        case .date: return "date"
        case .notification(let config): return "notification-\(config.selectedIndex.map(String.init) ?? "new")"
        case .placeSearch: return "placeSearch"
        }
    }
}

extension WishFormViewModel {
    enum Action: Equatable {
        case onAppear
        case hideTooltip
        case tapEmoji
        case selectEmoji(String)
        case tapRandomEmoji
        case selectCategory(Category)
        case inputTitle(String)
        case tapDate
        case inputDeadline(Date)
        case toggleDeadline(Bool)
        case toggleNotification(Bool)
        case tapAddNotification
        case tapNotification(index: Int)
        case saveNotification(SeepNotification, index: Int?)
        case deleteNotification(index: Int)
        case inputMemo(String)
        case tapAddStep
        case addStep(String)
        case deleteStep(index: Int)
        case inputTargetAmount(String)
        case inputLink(String)
        case pasteLink(String)
        case tapPlace
        case selectPlace(WishPlace)
        case deletePlace
        case selectHashtag(HashtagType)
        case inputCustomHashtag(String)
        case tapSave
        case tapClose
        case dismissSheet
        case routeHandled
    }

    enum Route: Equatable {
        case toast(String)
        case addStepAlert
        /// 저장한 위시(닫기면 nil)를 띄운 쪽에 넘긴다. 화면 닫기는 띄운 쪽이 한다
        case finish(Wish?)
    }

    struct State: Equatable {
        var isTooltipVisible = false
        var emoji = ""
        var category: Category
        var title = ""
        var titleError: String?
        var deadline: Date?
        var deadlineError: String?
        var isDeadlineEnabled = true
        var notifications: [SeepNotification] = [SeepNotification()]
        var isNotificationEnabled = true
        var memo = ""
        var memoError: String?
        var steps: [WishStep] = []
        /// 목표 금액(원). 갖고 싶어요일 때만 저장한다 (GH-16 R-1)
        var targetAmount = 0
        var linkText = ""
        var link: WishLinkInput = .empty
        var linkError: String?
        var linkPreview: WishFormLinkPreview = .hidden
        /// 붙인 장소. 작성의 가고 싶어요에서만 고르고 저장한다 (GH-31 R-1)
        var place: WishPlace?
        var selectedHashtag: HashtagType?
        var customHashtag = ""
        var customHashtagError: String?
        var saveButtonState: WishFormSaveButtonState
        var sheet: WishFormSheet?

        var isLinkVisible: Bool { category == .wantToGet }
        var isTargetAmountVisible: Bool { category == .wantToGet }
        var titlePlaceholder: String {
            switch category {
            case .wantToDo: return Strings.writePlaceholderTitleCategoryWantToDo
            case .wantToGet: return Strings.writePlaceholderTitleCategoryWantToGet
            case .wantToGo: return Strings.writePlaceholderTitleCategoryWantToGo
            }
        }
        var isAddStepEnabled: Bool { steps.count < WishStep.maxCount }
    }

    struct Config {
        let mode: WishFormMode
    }

    struct Dependency {
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        let userDefaults: UserDefaultsUtils
        let linkMetadataProvider: LinkMetadataProviding
        let linkPreviewCache: LinkPreviewCaching
        /// 링크 입력이 멈추고 이만큼 지나면 미리보기를 불러온다. nil 이면 바로 (테스트)
        let linkPreviewDelay: Duration?
        let randomEmoji: () -> String
        let now: () -> Date

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            userDefaults: UserDefaultsUtils = UserDefaultsUtils(),
            linkMetadataProvider: LinkMetadataProviding = LinkMetadataProvider(),
            linkPreviewCache: LinkPreviewCaching = LinkPreviewCache.shared,
            linkPreviewDelay: Duration? = .milliseconds(500),
            randomEmoji: @escaping () -> String = EmojiCatalog.randomEmoji,
            now: @escaping () -> Date = Date.init
        ) {
            self.wishRepository = wishRepository
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.userDefaults = userDefaults
            self.linkMetadataProvider = linkMetadataProvider
            self.linkPreviewCache = linkPreviewCache
            self.linkPreviewDelay = linkPreviewDelay
            self.randomEmoji = randomEmoji
            self.now = now
        }
    }
}

/// 위시 작성·수정 폼 (GH-64 P2). 레거시 `WriteReactor`·`WishEditReactor`와 단계·링크·장소 섹션 ViewModel 의
/// 작성·수정 동작을 하나로 옮겼다. 저장 규칙(카테고리별로 버리는 값, 고정 해제 등)은 레거시와 같다
@Observable
final class WishFormViewModel {
    static let titleMaxLength = 18
    static let memoMaxLength = 300
    static let customHashtagMaxLength = 7

    private(set) var state: State
    private(set) var route: Route?

    let screenName: ScreenName
    private let config: Config
    private let dependency: Dependency
    private var hasSentLinkPreviewImpression = false
    private var linkPreviewTask: Task<Void, Never>?

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        switch config.mode {
        case .add(let category):
            screenName = .write
            state = State(category: category, saveButtonState: .initial)
        case .edit(let wish):
            screenName = .wishEdit
            let hashtag = HashtagType(rawValue: wish.hashtag)
            state = State(
                emoji: wish.emoji,
                category: wish.category,
                title: wish.title,
                deadline: wish.endDate,
                isDeadlineEnabled: wish.endDate != nil,
                notifications: wish.notifications.isEmpty ? [SeepNotification()] : wish.notifications,
                isNotificationEnabled: !wish.notifications.isEmpty,
                memo: wish.memo,
                steps: wish.steps,
                targetAmount: wish.targetAmount,
                linkText: wish.link,
                link: WishLinkInput(text: wish.link),
                place: wish.place,
                selectedHashtag: hashtag,
                customHashtag: hashtag == nil ? wish.hashtag : "",
                saveButtonState: .active
            )
            state.saveButtonState = validatedButtonState()
        }
    }

    private var isEditMode: Bool {
        if case .edit = config.mode { return true }
        return false
    }

    /// 장소는 작성 화면에서만 고른다. 수정 화면은 상세에서 바꾼다 (GH-31 R-10)
    var isPlaceVisible: Bool {
        !isEditMode && state.category == .wantToGo
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            handleAppear()
        case .hideTooltip:
            state.isTooltipVisible = false
        case .tapEmoji:
            state.sheet = .emoji
        case .selectEmoji(let emoji):
            state.emoji = emoji
            state.sheet = nil
        case .tapRandomEmoji:
            state.emoji = dependency.randomEmoji()
        case .selectCategory(let category):
            state.category = category
            updateButtonState()
        case .inputTitle(let title):
            inputTitle(title)
        case .tapDate:
            guard state.isDeadlineEnabled else { return }
            if state.deadline == nil {
                state.deadline = dependency.now().endOfDay
            }
            state.deadlineError = nil
            state.sheet = .date
        case .inputDeadline(let date):
            state.deadline = date.endOfDay
            state.deadlineError = nil
        case .toggleDeadline(let isEnabled):
            state.isDeadlineEnabled = isEnabled
            state.deadlineError = nil
            state.isNotificationEnabled = isEnabled
        case .toggleNotification(let isEnabled):
            toggleNotification(isEnabled)
        case .tapAddNotification:
            guard state.isNotificationEnabled else { return }
            state.sheet = .notification(NotificationEditorConfig(notifications: state.notifications, selectedIndex: nil))
        case .tapNotification(let index):
            guard state.isNotificationEnabled, state.notifications.indices.contains(index) else { return }
            state.sheet = .notification(NotificationEditorConfig(notifications: state.notifications, selectedIndex: index))
        case .saveNotification(let notification, let index):
            if let index, state.notifications.indices.contains(index) {
                state.notifications[index] = notification
            } else {
                state.notifications.append(notification)
            }
            state.sheet = nil
        case .deleteNotification(let index):
            if state.notifications.indices.contains(index) {
                state.notifications.remove(at: index)
            }
            state.sheet = nil
        case .inputMemo(let memo):
            if memo.count > Self.memoMaxLength {
                state.memo = String(memo.prefix(Self.memoMaxLength))
            } else {
                state.memo = memo
            }
            state.memoError = memo.count >= Self.memoMaxLength ? Strings.writeErrorMaxLengthMemo : nil
        case .tapAddStep:
            guard state.isAddStepEnabled else {
                route = .toast(Strings.Detail.Step.Toast.maxCount)
                return
            }
            route = .addStepAlert
        case .addStep(let title):
            addStep(title: title)
        case .deleteStep(let index):
            deleteStep(index: index)
        case .inputTargetAmount(let text):
            state.targetAmount = AmountFormatter.amount(from: text)
        case .inputLink(let text):
            updateLink(text: text)
        case .pasteLink(let text):
            sendClickLog(objectType: .button, objectId: .pasteWishLink)
            updateLink(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        case .tapPlace:
            sendClickLog(objectType: .button, objectId: .addPlace)
            state.sheet = .placeSearch
        case .selectPlace(let place):
            state.place = place
            state.sheet = nil
        case .deletePlace:
            state.place = nil
        case .selectHashtag(let hashtag):
            state.customHashtag = ""
            state.customHashtagError = nil
            state.selectedHashtag = hashtag
        case .inputCustomHashtag(let text):
            inputCustomHashtag(text)
        case .tapSave:
            save()
        case .tapClose:
            linkPreviewTask?.cancel()
            route = .finish(nil)
        case .dismissSheet:
            state.sheet = nil
        case .routeHandled:
            route = nil
        }
    }

    // MARK: 입력

    private func handleAppear() {
        if !isEditMode, !dependency.userDefaults.getRandomEmojiTooltipIsShow() {
            state.isTooltipVisible = true
            dependency.userDefaults.setRandomEmojiTooltipIsShow(isShown: true)
        }
        // 수정: 저장된 링크의 미리보기를 캐시에서 먼저 찾는다 (GH-29 R-5)
        if case .edit(let wish) = config.mode, let link = state.link.link {
            loadStoredPreview(wishId: wish.id, link: link)
        }
    }

    private func inputTitle(_ title: String) {
        // 18자를 넘게 들어오면 자르고, 18자에 닿으면 안내한다 (레거시 shouldChangeCharacters)
        let limited = String(title.prefix(Self.titleMaxLength))
        state.title = limited
        state.titleError = title.count >= Self.titleMaxLength ? Strings.writeErrorMaxLengthTitle : nil
        updateButtonState()
    }

    private func toggleNotification(_ isEnabled: Bool) {
        guard state.isDeadlineEnabled else {
            state.isNotificationEnabled = false
            route = .toast(Strings.WishForm.notificationRequiresDate)
            return
        }
        state.isNotificationEnabled = isEnabled
    }

    private func inputCustomHashtag(_ text: String) {
        state.selectedHashtag = nil
        state.customHashtag = String(text.prefix(Self.customHashtagMaxLength))
        state.customHashtagError = text.count >= Self.customHashtagMaxLength ? Strings.writeErrorMaxLengthHashtag : nil
    }

    // MARK: 단계 (GH-5)

    private func addStep(title: String) {
        guard state.isAddStepEnabled else {
            route = .toast(Strings.Detail.Step.Toast.maxCount)
            return
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard trimmedTitle.count <= WishStep.maxTitleLength else {
            route = .toast(Strings.Detail.Step.Toast.maxLength)
            return
        }
        state.steps.append(WishStep(title: trimmedTitle, order: state.steps.count))
        sendClickLog(objectType: .button, objectId: .addStep)
    }

    private func deleteStep(index: Int) {
        guard state.steps.indices.contains(index) else { return }
        let removedId = state.steps[index].id
        state.steps = state.steps
            .filter { $0.id != removedId }
            .enumerated()
            .map { order, step in WishStep(id: step.id, title: step.title, isDone: step.isDone, order: order) }
    }

    // MARK: 링크 (GH-29)

    private func updateLink(text: String) {
        let previousLink = state.link.link
        let link = WishLinkInput(text: text)
        state.linkText = text
        state.link = link
        state.linkError = link == .invalid ? Strings.Write.Link.errorInvalid : nil
        updateButtonState()

        guard let validLink = link.link else {
            linkPreviewTask?.cancel()
            state.linkPreview = .hidden
            return
        }
        // 같은 링크에 공백만 붙었다 지워진 경우는 다시 부르지 않는다
        guard validLink != previousLink || state.linkPreview == .hidden else { return }
        state.linkPreview = .loading(domain: WishLinkInput.domain(of: validLink))
        schedulePreview(link: validLink)
    }

    private func schedulePreview(link: String) {
        linkPreviewTask?.cancel()
        guard let delay = dependency.linkPreviewDelay else {
            fetchPreview(link: link)
            return
        }
        linkPreviewTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self, self.state.link.link == link else { return }
            self.fetchPreview(link: link)
        }
    }

    /// 수정: 캐시에 같은 링크가 있으면 네트워크 없이 보여준다 (GH-29 R-5)
    private func loadStoredPreview(wishId: String, link: String) {
        if let cached = dependency.linkPreviewCache.preview(wishId: wishId), cached.link == link {
            showPreview(.loaded(cached))
            return
        }
        state.linkPreview = .loading(domain: WishLinkInput.domain(of: link))
        fetchPreview(link: link)
    }

    private func fetchPreview(link: String) {
        dependency.linkMetadataProvider.fetchPreview(link: link) { [weak self] preview in
            guard let self else { return }
            // 응답이 오기 전에 링크가 바뀌었으면 버린다 (GH-29 R-3)
            guard self.state.link.link == link else { return }
            if let preview {
                self.showPreview(.loaded(preview))
            } else {
                self.showPreview(.failed(domain: WishLinkInput.domain(of: link)))
            }
        }
    }

    private func showPreview(_ preview: WishFormLinkPreview) {
        state.linkPreview = preview
        // 작성·수정 중 미리보기 카드가 처음 뜰 때 한 번만 (GH-29 TC-11)
        guard !hasSentLinkPreviewImpression else { return }
        hasSentLinkPreviewImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .card,
            objectId: .wishLinkPreview
        ))
    }

    // MARK: 저장

    private func updateButtonState() {
        state.saveButtonState = validatedButtonState()
    }

    private func validatedButtonState() -> WishFormSaveButtonState {
        let isBlocked = state.title.isEmpty || state.link.blocksSave(category: state.category)
        guard isBlocked else { return .active }
        return isEditMode ? .more : .initial
    }

    private func save() {
        var hasError = false
        if state.title.isEmpty {
            state.titleError = Strings.writeErrorTitleEmpty
            hasError = true
        }
        if state.isDeadlineEnabled && state.deadline == nil {
            state.deadlineError = Strings.writeErrorDateEmpty
            hasError = true
        }
        // 링크 형식 안내는 링크 칸이 이미 보여준다 (GH-29 R-2)
        guard !hasError, !state.link.blocksSave(category: state.category) else { return }

        switch config.mode {
        case .add:
            addWish()
        case .edit(let original):
            updateWish(original: original)
        }
    }

    private var hashtag: String {
        if !state.customHashtag.isEmpty { return state.customHashtag }
        return state.selectedHashtag?.rawValue ?? ""
    }

    private func addWish() {
        let wish = Wish(
            emoji: state.emoji.isEmpty ? dependency.randomEmoji() : state.emoji,
            category: state.category,
            title: state.title,
            endDate: state.isDeadlineEnabled ? state.deadline : nil,
            notifications: state.isNotificationEnabled ? state.notifications : [],
            steps: state.steps,
            // 다른 카테고리로 바꿨으면 입력했던 목표 금액은 버린다 (GH-16 R-1)
            targetAmount: state.category == .wantToGet ? state.targetAmount : 0,
            memo: state.memo,
            hashtag: hashtag,
            // 다른 카테고리로 바꿨으면 링크도 버린다 (GH-29 R-1)
            link: state.link.storedLink(category: state.category),
            // 다른 카테고리로 바꿨으면 골랐던 장소는 버린다 (GH-31 R-1)
            place: state.category == .wantToGo ? state.place : nil,
            createdAt: dependency.now()
        )

        switch dependency.wishRepository.addWish(wish) {
        case .success(let saved):
            dependency.notificationManager.reserveNotifications(wish: saved)
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: .write,
                objectType: .button,
                objectId: .write,
                extraParameters: [.hasTargetAmount: saved.targetAmount > 0]
            ))
            linkPreviewTask?.cancel()
            route = .finish(saved)
        case .failure(let error):
            route = .toast(error.localizedDescription)
        }
    }

    private func updateWish(original: Wish) {
        let wish = Wish(
            id: original.id,
            emoji: state.emoji.isEmpty ? dependency.randomEmoji() : state.emoji,
            category: state.category,
            title: state.title,
            endDate: state.isDeadlineEnabled ? state.deadline : nil,
            finishDate: original.finishDate,
            notifications: state.isNotificationEnabled ? state.notifications : [],
            steps: state.steps,
            // 다른 카테고리로 바꿨으면 목표 금액은 0 으로 저장하고 기록은 남긴다 (GH-16 R-1)
            targetAmount: state.category == .wantToGet ? state.targetAmount : 0,
            savings: original.savings,
            memo: state.memo,
            hashtag: hashtag,
            isSuccess: original.isSuccess,
            finishNote: original.finishNote,
            // 옮겨 간 카테고리의 고정 3개 제한을 넘지 않도록, 카테고리를 바꾸면 고정을 푼다 (GH-33 R-9)
            pinnedAt: state.category == original.category ? original.pinnedAt : nil,
            // 다른 카테고리로 바꿨으면 링크는 빈 문자열로 저장한다 (GH-29 R-1)
            link: state.link.storedLink(category: state.category),
            // 홈이 돌려받은 위시로 잠든 위시 카드를 다시 판단한다 (GH-30 R-2)
            lastCheckedAt: dependency.now(),
            // 수정 폼은 장소·사진을 바꾸지 않는다 (GH-31 R-10, GH-36 R-10)
            place: original.place,
            photoFileName: original.photoFileName,
            createdAt: original.createdAt
        )

        switch dependency.wishRepository.updateWish(wish) {
        case .success(let saved):
            // 지운 알림까지 지우도록 수정 전 위시의 알림을 지우고 새로 예약한다
            dependency.notificationManager.cancelNotifications(wish: original)
            dependency.notificationManager.reserveNotifications(wish: saved)
            linkPreviewTask?.cancel()
            route = .finish(saved)
        case .failure(let error):
            route = .toast(error.localizedDescription)
        }
    }

    private func sendClickLog(objectType: LogObjectType, objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: objectType,
            objectId: objectId
        ))
    }
}
