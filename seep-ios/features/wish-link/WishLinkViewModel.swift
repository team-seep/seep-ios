import Foundation
import Combine


extension WishLinkViewModel {
    struct Input {
        /// 화면이 뜰 때 저장된 링크의 미리보기를 불러온다 (수정·상세)
        let viewDidLoad = PassthroughSubject<Void, Never>()
        /// 링크 칸 입력 (작성·수정)
        let inputText = PassthroughSubject<String, Never>()
        /// 링크 칸의 "붙여넣기"로 들어온 값 (R-6)
        let paste = PassthroughSubject<String, Never>()
        let changeCategory = PassthroughSubject<Category, Never>()
        /// 상세 링크 카드 탭 (R-4)
        let didTapCard = PassthroughSubject<Void, Never>()
        /// 수정 화면에서 돌아와 위시가 바뀌면 링크·카테고리를 갈아끼운다 (상세)
        let reloadWish = PassthroughSubject<Wish, Never>()
    }

    struct Output {
        let screenName: ScreenName
        let isVisible: CurrentValueSubject<Bool, Never>
        /// 붙여넣기처럼 칸의 글자를 바꿔야 할 때 보낸다
        let text = PassthroughSubject<String, Never>()
        let errorMessage = CurrentValueSubject<String?, Never>(nil)
        let preview = CurrentValueSubject<WishLinkPreviewState, Never>(.hidden)
        /// 작성·수정 Reactor 로 넘기는 검증된 링크 (R-8)
        let linkInput: CurrentValueSubject<WishLinkInput, Never>
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case openSafari(URL)
    }

    enum Mode {
        case write
        case edit
        case detail

        var screenName: ScreenName {
            switch self {
            case .write: return .write
            case .edit: return .wishEdit
            case .detail: return .wishDetail
            }
        }
    }

    struct Config {
        let mode: Mode
        let category: Category
        /// 작성 화면은 저장 전이라 id 가 없다
        let wishId: String?
        let link: String

        init(mode: Mode, category: Category, wishId: String? = nil, link: String = "") {
            self.mode = mode
            self.category = category
            self.wishId = wishId
            self.link = link
        }
    }

    struct State {
        var category: Category
        var linkInput: WishLinkInput
        var hasSentPreviewImpression = false
    }

    struct Dependency {
        let linkMetadataProvider: LinkMetadataProviding
        let linkPreviewCache: LinkPreviewCaching
        let logManager: LogManagerProtocol
        /// 입력이 멈추고 이만큼 지나면 미리보기를 불러온다. nil 이면 바로 (테스트)
        let debounceInterval: DispatchQueue.SchedulerTimeType.Stride?

        init(
            linkMetadataProvider: LinkMetadataProviding = LinkMetadataProvider(),
            linkPreviewCache: LinkPreviewCaching = LinkPreviewCache.shared,
            logManager: LogManagerProtocol = LogManager.shared,
            debounceInterval: DispatchQueue.SchedulerTimeType.Stride? = .milliseconds(500)
        ) {
            self.linkMetadataProvider = linkMetadataProvider
            self.linkPreviewCache = linkPreviewCache
            self.logManager = logManager
            self.debounceInterval = debounceInterval
        }
    }
}

/// 갖고 싶어요의 상품 링크 칸·미리보기 카드 (GH-29). 작성·수정·상세는 레거시 Reactor 화면이라
/// 단계(#5)·모으기(#16) 섹션처럼 이 섹션만 Combine ViewModel 로 붙이고, Reactor 에는 `linkInput` 만 넘긴다.
final class WishLinkViewModel {
    let input = Input()
    let output: Output
    private var state: State
    private let config: Config
    private let dependency: Dependency
    private let fetchTrigger = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        let linkInput = WishLinkInput(text: config.link)
        self.state = State(category: config.category, linkInput: linkInput)
        self.output = Output(
            screenName: config.mode.screenName,
            isVisible: .init(Self.isVisible(mode: config.mode, category: config.category, linkInput: linkInput)),
            linkInput: .init(linkInput)
        )

        bind()
    }

    private func bind() {
        input.viewDidLoad
            .withUnretained(self)
            .sink { (owner: WishLinkViewModel, _) in
                guard let link = owner.state.linkInput.link else { return }
                owner.loadPreview(link: link)
            }
            .store(in: &cancellables)

        input.inputText
            .withUnretained(self)
            .sink { (owner: WishLinkViewModel, text: String) in
                owner.updateLink(text: text)
            }
            .store(in: &cancellables)

        input.paste
            .withUnretained(self)
            .sink { (owner: WishLinkViewModel, text: String) in
                owner.sendClickLog(objectType: .button, objectId: .pasteWishLink)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                owner.output.text.send(trimmed)
                owner.updateLink(text: trimmed)
            }
            .store(in: &cancellables)

        input.changeCategory
            .withUnretained(self)
            .sink { (owner: WishLinkViewModel, category: Category) in
                owner.state.category = category
                owner.updateVisibility()
            }
            .store(in: &cancellables)

        input.didTapCard
            .withUnretained(self)
            .sink { (owner: WishLinkViewModel, _) in
                owner.openLink()
            }
            .store(in: &cancellables)

        input.reloadWish
            .withUnretained(self)
            .sink { (owner: WishLinkViewModel, wish: Wish) in
                owner.reload(wish: wish)
            }
            .store(in: &cancellables)

        bindFetchTrigger()
    }

    private func bindFetchTrigger() {
        let trigger: AnyPublisher<String, Never>
        if let debounceInterval = dependency.debounceInterval {
            trigger = fetchTrigger
                .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        } else {
            trigger = fetchTrigger.eraseToAnyPublisher()
        }

        trigger
            .withUnretained(self)
            .sink { (owner: WishLinkViewModel, link: String) in
                // 기다리는 동안 칸이 바뀌었으면 부르지 않는다
                guard owner.state.linkInput.link == link else { return }
                owner.fetchPreview(link: link)
            }
            .store(in: &cancellables)
    }

    private func updateLink(text: String) {
        let linkInput = WishLinkInput(text: text)
        let previousLink = state.linkInput.link
        state.linkInput = linkInput
        output.linkInput.send(linkInput)
        output.errorMessage.send(linkInput == .invalid ? Strings.Write.Link.errorInvalid : nil)

        guard let link = linkInput.link else {
            output.preview.send(.hidden)
            return
        }
        // 같은 링크에 공백만 붙었다 지워진 경우는 다시 부르지 않는다
        guard link != previousLink || output.preview.value == .hidden else { return }
        output.preview.send(.loading(domain: WishLinkInput.domain(of: link)))
        fetchTrigger.send(link)
    }

    /// 수정·상세: 캐시에 같은 링크가 있으면 네트워크 없이 보여준다 (R-5, TC-10)
    private func loadPreview(link: String) {
        if let wishId = config.wishId, let cached = dependency.linkPreviewCache.preview(wishId: wishId) {
            if cached.link == link {
                show(preview: .loaded(cached))
                return
            }
            // 링크가 바뀌었으면 예전 미리보기는 버린다 (R-5)
            dependency.linkPreviewCache.remove(wishId: wishId)
        }
        output.preview.send(.loading(domain: WishLinkInput.domain(of: link)))
        fetchPreview(link: link)
    }

    private func fetchPreview(link: String) {
        dependency.linkMetadataProvider.fetchPreview(link: link) { [weak self] preview in
            guard let self else { return }
            // 응답이 오기 전에 링크가 바뀌었으면 버린다 (R-3)
            guard state.linkInput.link == link else { return }

            guard let preview else {
                show(preview: .failed(domain: WishLinkInput.domain(of: link)))
                return
            }
            // 저장된 링크의 미리보기만 캐시한다. 작성·수정 중 입력은 저장되지 않을 수 있다
            if config.mode == .detail, let wishId = config.wishId {
                dependency.linkPreviewCache.save(preview, wishId: wishId)
            }
            show(preview: .loaded(preview))
        }
    }

    private func show(preview: WishLinkPreviewState) {
        output.preview.send(preview)
        sendPreviewImpressionIfNeeded()
    }

    private func reload(wish: Wish) {
        let linkInput = WishLinkInput(text: wish.link)
        let isLinkChanged = linkInput != state.linkInput
        state.category = wish.category
        state.linkInput = linkInput
        output.linkInput.send(linkInput)
        updateVisibility()

        guard isLinkChanged else { return }
        if let wishId = config.wishId {
            dependency.linkPreviewCache.remove(wishId: wishId)
        }
        if let link = linkInput.link {
            loadPreview(link: link)
        } else {
            output.preview.send(.hidden)
        }
    }

    private func openLink() {
        guard config.mode == .detail,
              let link = state.linkInput.link,
              let url = URL(string: link) else { return }
        sendClickLog(objectType: .card, objectId: .wishLink)
        output.route.send(.openSafari(url))
    }

    private func updateVisibility() {
        output.isVisible.send(Self.isVisible(mode: config.mode, category: state.category, linkInput: state.linkInput))
    }

    /// 작성·수정: 갖고 싶어요면 칸을 보인다. 상세: 갖고 싶어요 + 링크가 있을 때만 (R-1, R-4)
    private static func isVisible(mode: Mode, category: Category, linkInput: WishLinkInput) -> Bool {
        guard category == .wantToGet else { return false }
        switch mode {
        case .write, .edit:
            return true
        case .detail:
            return linkInput.link != nil
        }
    }

    /// 작성·수정 중 미리보기 카드가 처음 뜰 때 한 번만 (TC-11)
    private func sendPreviewImpressionIfNeeded() {
        guard config.mode != .detail, state.hasSentPreviewImpression == false else { return }
        state.hasSentPreviewImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .wishLinkPreview
        ))
    }

    private func sendClickLog(objectType: LogObjectType, objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: objectType,
            objectId: objectId
        ))
    }
}
