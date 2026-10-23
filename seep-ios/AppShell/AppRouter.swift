import Foundation
import Observation

/// 메인 탭 (GH-64 R-1). 적기는 탭이 아니라 시트라 여기 없다
enum MainTab: Hashable {
    case wish
    case finished
    case settings
}

/// 탭 내비게이션 스택에 쌓는 화면. 화면은 `DestinationView`가 고른다
enum AppDestination: Hashable {
    case wishDetail(id: String, isFinished: Bool)
    /// 검색. 이룬 싶 탭에서 열면 완료한 위시만 찾는다 (R-19)
    case search(finishedOnly: Bool)
    case badgeCollection
    case yearReviewList(year: Int)
    case placeMap
    case widgetGuide
    case controlGuide
    case license
}

extension Category: Identifiable {
    var id: String { rawValue }
}

/// 위젯 링크를 앱이 뜨기 전까지 맡아 두는 곳 (GH-50 `Preference.reservedDeepLink`)
protocol ReservedDeepLinkStoring: AnyObject {
    var reservedDeepLink: String { get set }
}

extension Preference: ReservedDeepLinkStoring {}

/// 탭 선택·탭별 내비게이션 path·작성 화면 표시를 한 곳에서 들고, 위젯·컨트롤 링크를 화면 이동으로 바꾼다 (GH-64 A-4, R-30).
/// 로그는 이동을 결정한 쪽(`handle`의 반환값을 받은 곳)이 남긴다
@Observable
final class AppRouter {
    struct Dependency {
        let wishRepository: WishRepository
        let deepLinkStore: ReservedDeepLinkStoring

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            deepLinkStore: ReservedDeepLinkStoring = Preference.shared
        ) {
            self.wishRepository = wishRepository
            self.deepLinkStore = deepLinkStore
        }
    }

    var selectedTab: MainTab = .wish
    var wishPath: [AppDestination] = []
    var finishedPath: [AppDestination] = []
    var settingsPath: [AppDestination] = []
    /// 작성 화면을 띄울 카테고리. nil 이면 닫혀 있다
    var writeCategory: Category?
    /// 스플래시가 끝나 메인 탭이 보이는지. 그 전에 온 링크는 맡아 뒀다가 메인이 뜰 때 처리한다
    private(set) var isMainReady = false
    /// `seepSheet`로 띄운 시트 수. 시트가 떠 있으면 위젯 링크를 무시한다
    private(set) var presentedModalCount = 0
    /// 싶 탭에서 마지막으로 고른 카테고리. 적기 시트가 기본 선택으로 쓴다 (R-8)
    var homeCategory: Category = .wantToDo
    /// 싶 탭에서 완료한 뒤 이룬 싶 탭 아이콘에 붙는 점 (R-14)
    var showsFinishedDot = false
    /// 값이 바뀌면 떠 있는 `seepSheet`·풀스크린이 모두 닫힌다 (단축어로 작성 화면을 맨 위에 띄울 때)
    private(set) var dismissAllModalsToken = 0
    /// 지금 탭을 다시 누르면 올라가는 값. 각 탭 루트 목록이 맨 위로 스크롤한다 (R-4)
    private(set) var scrollToTopToken: [MainTab: Int] = [:]
    /// 작성·수정으로 위시가 바뀌면 올라가는 값. 풀스크린이 닫혀도 onAppear 가 다시 오지 않아 목록이 이 값으로 다시 읽는다
    private(set) var wishesChangedToken = 0

    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    /// 탭 루트 위에 무언가 떠 있는지(어느 탭의 push 든, 시트·작성 화면이든)
    var isShowingAboveRoot: Bool {
        presentedModalCount > 0
            || writeCategory != nil
            || !wishPath.isEmpty
            || !finishedPath.isEmpty
            || !settingsPath.isEmpty
    }

    func wishesDidChange() {
        wishesChangedToken += 1
    }

    func modalDidAppear() {
        presentedModalCount += 1
    }

    func modalDidDisappear() {
        presentedModalCount = max(0, presentedModalCount - 1)
        presentPendingIntentIfPossible()
    }

    func select(_ tab: MainTab) {
        if tab == selectedTab {
            // 지금 탭을 다시 누르면 루트로 돌아가고, 이미 루트면 맨 위로 스크롤한다 (R-4)
            if path(for: tab).isEmpty {
                scrollToTopToken[tab, default: 0] += 1
            } else {
                setPath([], for: tab)
            }
        } else {
            selectedTab = tab
        }
        if tab == .finished {
            showsFinishedDot = false
        }
    }

    func path(for tab: MainTab) -> [AppDestination] {
        switch tab {
        case .wish: return wishPath
        case .finished: return finishedPath
        case .settings: return settingsPath
        }
    }

    func setPath(_ path: [AppDestination], for tab: MainTab) {
        switch tab {
        case .wish: wishPath = path
        case .finished: finishedPath = path
        case .settings: settingsPath = path
        }
    }

    /// 지금 탭에 화면을 쌓는다
    func push(_ destination: AppDestination) {
        var current = path(for: selectedTab)
        current.append(destination)
        setPath(current, for: selectedTab)
    }

    /// 싶 적기 컨트롤·단축어(GH-49). 위젯 링크와 달리 다른 화면이 떠 있어도 작성 화면을 맨 위에 띄운다 (GH-49 R-5, R-12).
    /// 시트가 떠 있으면 먼저 모두 닫고, 닫히는 애니메이션이 끝난 뒤 작성 화면을 띄운다
    @discardableResult
    func openFromIntent(_ deepLink: WidgetDeepLink) -> WidgetDeepLink? {
        guard case .add(let category, _) = deepLink, let url = deepLink.url else {
            return deepLink.url.flatMap { open(url: $0) }
        }
        guard isMainReady else {
            dependency.deepLinkStore.reservedDeepLink = url.absoluteString
            return nil
        }
        if writeCategory != nil {
            writeCategory = category
            return deepLink
        }
        if presentedModalCount > 0 {
            dismissAllModalsToken += 1
            pendingIntentCategory = category
            return deepLink
        }
        writeCategory = category
        return deepLink
    }

    /// 시트가 모두 닫힌 뒤(`modalDidDisappear`로 0이 되면) 미뤄 둔 작성 화면을 띄운다
    private var pendingIntentCategory: Category? {
        didSet { presentPendingIntentIfPossible() }
    }

    private func presentPendingIntentIfPossible() {
        guard let category = pendingIntentCategory, presentedModalCount == 0 else { return }
        pendingIntentCategory = nil
        writeCategory = category
    }

    /// `.onOpenURL`로 받은 위젯 링크. 메인이 아직 없으면 맡아 두고, 있으면 바로 처리한다
    @discardableResult
    func open(url: URL) -> WidgetDeepLink? {
        guard WidgetDeepLink(string: url.absoluteString) != nil else { return nil }
        dependency.deepLinkStore.reservedDeepLink = url.absoluteString
        guard isMainReady else { return nil }
        return consumeReservedDeepLink()
    }

    /// 스플래시가 끝나고 메인 탭이 처음 보일 때 부른다
    @discardableResult
    func mainDidAppear() -> WidgetDeepLink? {
        isMainReady = true
        return consumeReservedDeepLink()
    }

    /// 맡아 둔 링크를 한 번 처리하고 지운다. 실제로 화면을 옮겼으면 그 링크를 돌려준다
    @discardableResult
    func consumeReservedDeepLink() -> WidgetDeepLink? {
        let reserved = dependency.deepLinkStore.reservedDeepLink
        guard !reserved.isEmpty else { return nil }
        dependency.deepLinkStore.reservedDeepLink = ""

        guard let deepLink = WidgetDeepLink(string: reserved) else { return nil }
        return handle(deepLink) ? deepLink : nil
    }

    /// 링크를 화면 이동으로 바꾼다. 옮겼으면 true
    @discardableResult
    func handle(_ deepLink: WidgetDeepLink) -> Bool {
        // 작성 화면이 떠 있을 때 다시 적기 링크가 오면 카테고리만 바꾼다 (GH-49 R-5)
        if case .add(let category, _) = deepLink, writeCategory != nil {
            writeCategory = category
            return true
        }
        // 다른 화면이 떠 있으면 링크를 버린다. 남기면 다음 실행 때 엉뚱한 화면이 열린다 (GH-50)
        guard !isShowingAboveRoot else { return false }

        switch deepLink {
        case .add(let category, _):
            writeCategory = category
            return true

        case .wish(let id, _):
            // 위젯이 갱신되기 전에 위시가 지워졌으면 홈만 보여준다 (GH-47 R-10, GH-48 R-9)
            guard let wish = dependency.wishRepository.fetchWish(id: id) else { return false }
            if wish.isSuccess {
                selectedTab = .finished
                finishedPath = [.wishDetail(id: id, isFinished: true)]
            } else {
                selectedTab = .wish
                wishPath = [.wishDetail(id: id, isFinished: false)]
            }
            return true

        case .home:
            selectedTab = .wish
            return true
        }
    }
}
