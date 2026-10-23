import Foundation
import Observation

extension DetailLinkViewModel {
    enum Action: Equatable {
        /// 섹션이 보일 때 저장된 링크의 미리보기를 불러온다
        case load
        /// 링크 줄·섹션 "열기" 탭 (GH-29 R-4)
        case tapCard
        /// 수정 화면에서 돌아와 링크·카테고리가 바뀌었다
        case reload(Wish)
        case routeHandled
    }

    enum Route: Equatable {
        case openURL(URL)
    }

    struct Config {
        let wish: Wish
    }

    struct State: Equatable {
        /// 갖고 싶어요 + 링크가 있을 때만 (GH-29 R-4)
        var isVisible: Bool
        var preview: WishLinkPreviewState = .hidden
    }

    struct Dependency {
        let linkMetadataProvider: LinkMetadataProviding
        let linkPreviewCache: LinkPreviewCaching
        let logManager: LogManagerProtocol

        init(
            linkMetadataProvider: LinkMetadataProviding = LinkMetadataProvider(),
            linkPreviewCache: LinkPreviewCaching = LinkPreviewCache.shared,
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.linkMetadataProvider = linkMetadataProvider
            self.linkPreviewCache = linkPreviewCache
            self.logManager = logManager
        }
    }
}

/// 상세 "링크" 섹션 (GH-29, GH-59 R-6). 저장된 링크의 미리보기를 캐시에서 먼저 보여주고, 없으면 불러와 위시 id 로 캐시한다
@Observable
final class DetailLinkViewModel {
    let screenName: ScreenName = .wishDetail
    private(set) var state: State
    private(set) var route: Route?

    private let wishId: String
    private var linkInput: WishLinkInput
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        let linkInput = WishLinkInput(text: config.wish.link)
        self.wishId = config.wish.id
        self.linkInput = linkInput
        self.dependency = dependency
        self.state = State(isVisible: Self.isVisible(category: config.wish.category, linkInput: linkInput))
    }

    func send(_ action: Action) {
        switch action {
        case .load:
            guard let link = linkInput.link, state.preview == .hidden else { return }
            loadPreview(link: link)
        case .tapCard:
            openLink()
        case .reload(let wish):
            reload(wish: wish)
        case .routeHandled:
            route = nil
        }
    }

    /// 캐시에 같은 링크가 있으면 네트워크 없이 보여준다 (GH-29 R-5)
    private func loadPreview(link: String) {
        if let cached = dependency.linkPreviewCache.preview(wishId: wishId) {
            if cached.link == link {
                state.preview = .loaded(cached)
                return
            }
            // 링크가 바뀌었으면 예전 미리보기는 버린다 (GH-29 R-5)
            dependency.linkPreviewCache.remove(wishId: wishId)
        }
        state.preview = .loading(domain: WishLinkInput.domain(of: link))
        fetchPreview(link: link)
    }

    private func fetchPreview(link: String) {
        dependency.linkMetadataProvider.fetchPreview(link: link) { [weak self] preview in
            guard let self else { return }
            // 응답이 오기 전에 링크가 바뀌었으면 버린다 (GH-29 R-3)
            guard linkInput.link == link else { return }
            guard let preview else {
                state.preview = .failed(domain: WishLinkInput.domain(of: link))
                return
            }
            dependency.linkPreviewCache.save(preview, wishId: wishId)
            state.preview = .loaded(preview)
        }
    }

    private func reload(wish: Wish) {
        let newLinkInput = WishLinkInput(text: wish.link)
        let isLinkChanged = newLinkInput != linkInput
        linkInput = newLinkInput
        state.isVisible = Self.isVisible(category: wish.category, linkInput: newLinkInput)
        guard isLinkChanged else { return }
        dependency.linkPreviewCache.remove(wishId: wishId)
        if let link = newLinkInput.link {
            loadPreview(link: link)
        } else {
            state.preview = .hidden
        }
    }

    private func openLink() {
        guard let link = linkInput.link, let url = URL(string: link) else { return }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .card,
            objectId: .wishLink
        ))
        route = .openURL(url)
    }

    private static func isVisible(category: Category, linkInput: WishLinkInput) -> Bool {
        category == .wantToGet && linkInput.link != nil
    }
}
