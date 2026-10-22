import Foundation
import Observation

/// 메인 탭 (GH-64 R-1). 적기는 탭이 아니라 시트라 여기 없다
enum MainTab: Hashable {
    case wish
    case finished
    case settings
}

/// 탭 내비게이션 스택에 쌓는 화면
enum AppDestination: Hashable {
    case wishDetail(id: String, isFinished: Bool)
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

    func modalDidAppear() {
        presentedModalCount += 1
    }

    func modalDidDisappear() {
        presentedModalCount = max(0, presentedModalCount - 1)
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
