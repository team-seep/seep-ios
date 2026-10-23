import Foundation

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

/// 문서에 꺼내 쓰는 칸 (GH-70 R-5, R-6). rawValue 는 `add_block` 로그의 `block` 값
enum WishDocumentBlock: String, CaseIterable, Hashable {
    case date
    case memo
    case steps
    case notification
    case link
    case targetAmount = "target_amount"
    case place

    /// 문서에 놓는 순서. 날짜는 머리의 D-day 줄이라 블록 목록에 없다 (R-5)
    static let documentOrder: [WishDocumentBlock] = [.memo, .steps, .notification, .link, .targetAmount, .place]
}

/// 폼이 띄우는 시트
enum WishFormSheet: Identifiable, Equatable {
    case emoji
    case date
    case notification(NotificationEditorConfig)
    case placeSearch
    case hashtag

    var id: String {
        switch self {
        case .emoji: return "emoji"
        case .date: return "date"
        case .notification(let config): return "notification-\(config.selectedIndex.map(String.init) ?? "new")"
        case .placeSearch: return "placeSearch"
        case .hashtag: return "hashtag"
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
        /// 하단 더하기 칩 (GH-70 R-6)
        case tapChip(WishDocumentBlock)
        /// 블록 "지우기", 날짜 시트 "날짜 없애기" (GH-70 R-7, R-8)
        case removeBlock(WishDocumentBlock)
        case tapHashtag
        /// 버리기 확인에서 "버리기" (GH-70 R-18)
        case confirmDiscard
    }

    enum Route: Equatable {
        case toast(String)
        case addStepAlert
        /// 저장한 위시(닫기면 nil)를 띄운 쪽에 넘긴다. 화면 닫기는 띄운 쪽이 한다
        case finish(Wish?)
        /// 칩으로 꺼낸 칸에 커서를 둔다 (GH-70 R-6)
        case focus(WishFormField)
        /// 바뀐 게 있을 때 닫으면 버릴지 묻는다 (GH-70 R-18)
        case confirmDiscard
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
        /// 칩으로 꺼낸 메모·단계·링크·목표 금액 블록. 날짜·알림·장소는 값 자체로 펼침을 정한다
        var revealedBlocks: Set<WishDocumentBlock> = []

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
