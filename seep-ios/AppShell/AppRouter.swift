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

/// 아이패드 사이드바 항목 (GH-99 R-4). 싶: 카테고리 3개 / 돌아보기: 이룬 싶·배지·지도 / 앱: 설정
enum PadSection: Hashable {
    case category(Category)
    case finished
    case badges
    case placeMap
    case settings
}

/// 아이패드에서 목록 옆 상세 열에 보이는 위시 (GH-99 R-5, R-7)
struct PadWishSelection: Hashable {
    let id: String
    let isFinished: Bool
}

extension Category: Identifiable {
    var id: String { rawValue }
}

/// 위젯 링크를 앱이 뜨기 전까지 맡아 두는 곳 (GH-50 `Preference.reservedDeepLink`)
protocol ReservedDeepLinkStoring: AnyObject {
    var reservedDeepLink: String { get set }
}

extension Preference: ReservedDeepLinkStoring {}

/// 홈 시작 카테고리 설정과 마지막으로 본 카테고리 (GH-86 R-1, R-2)
protocol HomeCategoryStoring: AnyObject {
    var startCategory: Category? { get }
    var lastHomeCategory: Category { get set }
}

extension Preference: HomeCategoryStoring {}

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
    var writeCategory: Category? {
        didSet {
            if writeCategory == nil { writePreviousWishId = nil }
        }
    }
    /// "이어서 적기"로 연 작성 화면의 앞 위시 id. 작성 화면이 닫히면 비운다 (GH-84 R-2)
    private(set) var writePreviousWishId: String?
    /// 스플래시가 끝나 메인 탭이 보이는지. 그 전에 온 링크는 맡아 뒀다가 메인이 뜰 때 처리한다
    private(set) var isMainReady = false
    /// `seepSheet`로 띄운 시트 수. 시트가 떠 있으면 위젯 링크를 무시한다
    private(set) var presentedModalCount = 0
    /// 싶 탭에서 마지막으로 고른 카테고리. 적기 시트가 기본 선택으로 쓴다 (R-8).
    /// 앱을 켤 때는 설정의 시작 카테고리(없으면 마지막으로 본 카테고리)로 시작한다 (GH-86 R-2)
    var homeCategory: Category = .wantToDo {
        didSet {
            categoryStore?.lastHomeCategory = homeCategory
            // 아이패드에서는 사이드바가 카테고리를 고른다. 작성을 마치고 카테고리가 바뀌면 사이드바도 따라간다 (GH-99 R-4)
            if isRegularLayout, case .category(let current) = padSection, current != homeCategory {
                padSection = .category(homeCategory)
                padSelection = nil
            }
        }
    }
    /// 싶 탭에서 완료한 뒤 이룬 싶 탭 아이콘에 붙는 점 (R-14)
    var showsFinishedDot = false
    /// 값이 바뀌면 떠 있는 `seepSheet`·풀스크린이 모두 닫힌다 (단축어로 작성 화면을 맨 위에 띄울 때)
    private(set) var dismissAllModalsToken = 0
    /// 지금 탭을 다시 누르면 올라가는 값. 각 탭 루트 목록이 맨 위로 스크롤한다 (R-4)
    private(set) var scrollToTopToken: [MainTab: Int] = [:]
    /// 작성·수정으로 위시가 바뀌면 올라가는 값. 풀스크린이 닫혀도 onAppear 가 다시 오지 않아 목록이 이 값으로 다시 읽는다
    private(set) var wishesChangedToken = 0

    // MARK: 아이패드 (GH-99)

    /// 화면 폭이 regular 인지. `setRegularLayout(_:)`으로만 바꾼다 (R-2)
    private(set) var isRegularLayout = false
    /// 사이드바에서 고른 항목 (R-4)
    private(set) var padSection: PadSection = .category(.wantToDo)
    /// 홈·이룬 싶 목록 옆 상세 열의 위시. nil 이면 빈 상세 (R-5, R-7)
    var padSelection: PadWishSelection?
    /// 설정 오른쪽 열의 하위 화면 (R-11)
    var padSettingsDetail: AppDestination?
    /// 배지·지도 열에 쌓는 화면. 이 두 항목은 상세 열이 없어 지금처럼 쌓는다
    var padSectionPath: [AppDestination] = []
    /// 홈이 그리드 보기인지. 그리드는 고른 위시가 없으면 상세 열을 닫고 넓게 쓴다 (R-5, TC-7)
    var padHomeUsesGrid = false
    /// regular 동안 DB 변경을 듣는다. 상세 열에서 바꾼 내용을 목록 열에 반영한다 (TC-4)
    private var wishChangeObservation: WishChangeObservation?

    private let dependency: Dependency

    /// 링크를 맡아 두는 `Preference`가 카테고리도 기억한다. 테스트 스텁이면 nil (GH-86)
    private var categoryStore: HomeCategoryStoring? {
        dependency.deepLinkStore as? HomeCategoryStoring
    }

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        if let store = dependency.deepLinkStore as? HomeCategoryStoring {
            homeCategory = store.startCategory ?? store.lastHomeCategory
        }
    }

    /// 탭 루트 위에 무언가 떠 있는지(어느 탭의 push 든, 시트·작성 화면이든)
    var isShowingAboveRoot: Bool {
        presentedModalCount > 0
            || writeCategory != nil
            || !wishPath.isEmpty
            || !finishedPath.isEmpty
            || !settingsPath.isEmpty
            || !padSectionPath.isEmpty
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

    /// 지금 탭에 화면을 쌓는다. 아이패드에서는 상세를 옆 열에, 배지·지도를 사이드바 항목으로 연다 (GH-99 R-5)
    func push(_ destination: AppDestination) {
        if isRegularLayout, routePadPush(destination) { return }
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

    /// 이룬 위시에 이어서 같은 카테고리의 작성 화면을 연다. 닫히는 시트가 있으면 다 닫힌 뒤 연다 (GH-84 R-1~R-3)
    func openChainedWrite(from wish: Wish) {
        guard writeCategory == nil else { return }
        writePreviousWishId = wish.id
        if presentedModalCount > 0 {
            pendingIntentCategory = wish.category
            return
        }
        writeCategory = wish.category
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
            if isRegularLayout {
                // 아이패드에서는 그 위시의 사이드바 항목 + 상세 열을 연다 (GH-99 R-13)
                selectPadSection(wish.isSuccess ? .finished : .category(wish.category))
                padSelection = PadWishSelection(id: id, isFinished: wish.isSuccess)
            } else if wish.isSuccess {
                selectedTab = .finished
                finishedPath = [.wishDetail(id: id, isFinished: true)]
            } else {
                selectedTab = .wish
                wishPath = [.wishDetail(id: id, isFinished: false)]
            }
            return true

        case .home:
            if isRegularLayout {
                if case .category = padSection {} else { selectPadSection(.category(homeCategory)) }
            } else {
                selectedTab = .wish
            }
            return true
        }
    }

    /// 작성을 마치면 그 카테고리의 홈을 보여준다 (GH-64 R-9, 아이패드는 사이드바 항목, GH-99)
    func showSavedWish(category: Category) {
        wishesDidChange()
        if isRegularLayout {
            selectPadSection(.category(category))
        } else {
            homeCategory = category
            select(.wish)
        }
    }

}

// MARK: - 아이패드 (GH-99)

extension AppRouter {
    /// 화면 폭이 바뀔 때 루트가 부른다. compact ↔ regular 로 바뀌어도 보던 카테고리·위시를 잇는다 (R-2, TC-5)
    func setRegularLayout(_ isRegular: Bool) {
        guard isRegular != isRegularLayout else { return }
        if isRegular {
            moveToPadLayout()
            wishChangeObservation = dependency.wishRepository.observeChanges { [weak self] in
                self?.wishesDidChange()
            }
        } else {
            moveToPhoneLayout()
            wishChangeObservation?.cancel()
            wishChangeObservation = nil
        }
        isRegularLayout = isRegular
    }

    /// 사이드바 항목을 고른다. 다른 항목으로 옮기면 그 열에 쌓인 화면·상세는 닫는다 (R-4)
    func selectPadSection(_ section: PadSection) {
        padSection = section
        padSelection = nil
        padSettingsDetail = nil
        padSectionPath = []
        // 보이지 않는 열의 스택도 비운다. 남아 있으면 `isShowingAboveRoot`가 위젯 링크를 막는다
        wishPath = []
        finishedPath = []
        settingsPath = []
        switch section {
        case .category(let category):
            selectedTab = .wish
            if homeCategory != category { homeCategory = category }
        case .finished:
            selectedTab = .finished
            showsFinishedDot = false
        case .badges:
            selectedTab = .finished
        case .placeMap:
            selectedTab = .wish
        case .settings:
            selectedTab = .settings
        }
    }

    /// 상세 열을 비운다(상세에서 지우기·완료 취소를 마쳤을 때)
    func closePadDetail() {
        padSelection = nil
    }

    /// 아이패드에서 다르게 여는 화면이면 열고 true. false 면 지금 탭에 쌓는다
    private func routePadPush(_ destination: AppDestination) -> Bool {
        switch destination {
        case .wishDetail(let id, let isFinished):
            switch padSection {
            case .category, .finished:
                padSelection = PadWishSelection(id: id, isFinished: isFinished)
                return true
            case .badges, .placeMap:
                padSectionPath.append(destination)
                return true
            case .settings:
                return false
            }
        case .badgeCollection:
            selectPadSection(.badges)
            return true
        case .placeMap:
            selectPadSection(.placeMap)
            return true
        case .widgetGuide, .controlGuide, .license:
            guard padSection == .settings else { return false }
            padSettingsDetail = destination
            return true
        case .search, .yearReviewList:
            switch padSection {
            case .badges, .placeMap:
                padSectionPath.append(destination)
                return true
            case .category, .finished, .settings:
                return false
            }
        }
    }

    /// 탭 + 쌓인 화면 → 사이드바 항목 + 상세 열
    private func moveToPadLayout() {
        var tabPath = path(for: selectedTab)
        switch selectedTab {
        case .wish:
            if tabPath.first == .placeMap {
                padSection = .placeMap
                padSectionPath = Array(tabPath.dropFirst())
                tabPath = []
            } else {
                padSection = .category(homeCategory)
            }
        case .finished:
            if tabPath.first == .badgeCollection {
                padSection = .badges
                padSectionPath = Array(tabPath.dropFirst())
                tabPath = []
            } else {
                padSection = .finished
            }
        case .settings:
            padSection = .settings
            if let last = tabPath.last, [.widgetGuide, .controlGuide, .license].contains(last) {
                padSettingsDetail = last
                tabPath.removeLast()
            }
        }
        if case .wishDetail(let id, let isFinished) = tabPath.last {
            padSelection = PadWishSelection(id: id, isFinished: isFinished)
            tabPath.removeLast()
        }
        setPath(tabPath, for: selectedTab)
    }

    /// 사이드바 항목 + 상세 열 → 탭 + 쌓인 화면
    private func moveToPhoneLayout() {
        switch padSection {
        case .placeMap:
            selectedTab = .wish
            wishPath = [.placeMap] + padSectionPath
        case .badges:
            selectedTab = .finished
            finishedPath = [.badgeCollection] + padSectionPath
        case .category, .finished:
            if let selection = padSelection {
                setPath(path(for: selectedTab) + [.wishDetail(id: selection.id, isFinished: selection.isFinished)], for: selectedTab)
            }
        case .settings:
            if let detail = padSettingsDetail {
                settingsPath.append(detail)
            }
        }
        padSelection = nil
        padSettingsDetail = nil
        padSectionPath = []
    }
}
