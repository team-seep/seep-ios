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
    /// 사진 한 장 (GH-61 R-10)
    case photo
    /// "미래의 나에게" 봉인 편지 — 문서 맨 아래 (GH-61 R-10)
    case letter = "future_letter"

    /// 문서에 놓는 순서. 날짜는 머리의 D-day 줄이라 블록 목록에 없다 (R-5)
    static let documentOrder: [WishDocumentBlock] = [.memo, .steps, .notification, .link, .targetAmount, .place, .photo, .letter]
}

/// 문서의 사진 블록 값 (GH-61 R-10, R-11). 고른 사진은 저장할 때 파일로 쓴다
enum WishFormPhoto: Equatable {
    case none
    /// 이미 저장된 사진 파일
    case stored(fileName: String)
    /// 새로 고른 사진 원본
    case picked(Data)
}

/// 사진 블록 미리보기 소스
enum WishFormPhotoPreview: Equatable {
    case file(URL)
    case data(Data)
}

/// 문서의 편지 블록 값. `sealedAt`이 nil 이면 이번에 봉인한 편지 — 저장 시각이 봉인일이 된다 (GH-61 R-11)
struct WishFormLetter: Equatable {
    let text: String
    let sealedAt: Date?
}

/// 폼이 띄우는 시트
enum WishFormSheet: Identifiable, Equatable {
    case emoji
    case date
    case notification(NotificationEditorConfig)
    case placeSearch
    case hashtag
    /// 편지 쓰기 시트 (GH-61 R-3, R-10)
    case letter(FutureLetterViewModel)

    var id: String {
        switch self {
        case .emoji: return "emoji"
        case .date: return "date"
        case .notification(let config): return "notification-\(config.selectedIndex.map(String.init) ?? "new")"
        case .placeSearch: return "placeSearch"
        case .hashtag: return "hashtag"
        case .letter: return "letter"
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
        /// 목표 금액 통화 고르기 (GH-103 R-15). 저금 기록이 있으면 바뀌지 않고 안내한다 (R-18)
        case selectCurrency(String)
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
        /// 사진 고르기에서 고른 이미지 원본 / 읽지 못함 (GH-61 R-10)
        case pickPhoto(Data)
        case pickPhotoFailed
        /// 사진 블록의 사진을 눌러 다시 고른다
        case tapPhoto
        /// 편지 시트에서 봉인했다
        case sealLetter(String)
        /// 봉인 카드를 눌렀다 → 다시 쓸지 묻는다 (R-4)
        case tapLetter
        case confirmRewriteLetter
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
        case photoPicker
        /// "봉인한 편지를 새로 쓸까요?" (GH-61 R-4)
        case rewriteLetterAlert
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
        /// 목표 금액(통화의 최소 단위). 갖고 싶어요일 때만 저장한다 (GH-16 R-1)
        var targetAmount = 0
        /// 목표 금액 칸에 보일 문자열. 소수가 있는 통화는 치는 중인 소수점을 남긴다 (GH-103 R-17)
        var targetAmountText = ""
        /// 목표 금액 통화(ISO 4217) (GH-103 R-15)
        var currency = AmountFormatter.krw
        /// 저금 기록이 있어 통화를 바꿀 수 없다 (GH-103 R-18)
        var isCurrencyLocked = false
        var linkText = ""
        var link: WishLinkInput = .empty
        var linkError: String?
        var linkPreview: WishFormLinkPreview = .hidden
        /// 붙인 장소. 작성의 가고 싶어요에서만 고르고 저장한다 (GH-31 R-1)
        var place: WishPlace?
        var photo: WishFormPhoto = .none
        var letter: WishFormLetter?
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
        /// "이어서 적기"로 연 작성의 앞 위시 id. 저장하면 새 위시의 `previousWishId`가 된다 (GH-84 R-2)
        var previousWishId: String?
    }

    struct Dependency {
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol
        let logManager: LogManagerProtocol
        let userDefaults: UserDefaultsUtils
        let linkMetadataProvider: LinkMetadataProviding
        let linkPreviewCache: LinkPreviewCaching
        let photoStorage: WishPhotoStorage
        /// 링크 입력이 멈추고 이만큼 지나면 미리보기를 불러온다. nil 이면 바로 (테스트)
        let linkPreviewDelay: Duration?
        let randomEmoji: () -> String
        let now: () -> Date
        /// 새로 적는 위시의 통화. 기기 지역 통화 (GH-103 R-15)
        let defaultCurrency: () -> String

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            userDefaults: UserDefaultsUtils = UserDefaultsUtils(),
            linkMetadataProvider: LinkMetadataProviding = LinkMetadataProvider(),
            linkPreviewCache: LinkPreviewCaching = LinkPreviewCache.shared,
            photoStorage: WishPhotoStorage = WishPhotoStorageImpl.shared,
            linkPreviewDelay: Duration? = .milliseconds(500),
            randomEmoji: @escaping () -> String = EmojiCatalog.randomEmoji,
            now: @escaping () -> Date = Date.init,
            defaultCurrency: @escaping () -> String = { AmountFormatter.defaultCurrency() }
        ) {
            self.wishRepository = wishRepository
            self.notificationManager = notificationManager
            self.logManager = logManager
            self.userDefaults = userDefaults
            self.linkMetadataProvider = linkMetadataProvider
            self.linkPreviewCache = linkPreviewCache
            self.photoStorage = photoStorage
            self.linkPreviewDelay = linkPreviewDelay
            self.randomEmoji = randomEmoji
            self.now = now
            self.defaultCurrency = defaultCurrency
        }
    }
}
