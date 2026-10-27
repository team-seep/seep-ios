import Foundation
import Observation

/// 아이패드 사이드바 줄 (그리는 순서대로). 싶: 카테고리 3개 / 돌아보기: 이룬 싶·배지·지도 / 앱: 설정 (GH-99 R-4)
enum PadSidebarItem: Hashable, CaseIterable {
    case wantToDo
    case wantToGet
    case wantToGo
    case finished
    case badges
    case placeMap
    case settings

    init(section: PadSection) {
        switch section {
        case .category(.wantToDo): self = .wantToDo
        case .category(.wantToGet): self = .wantToGet
        case .category(.wantToGo): self = .wantToGo
        case .finished: self = .finished
        case .badges: self = .badges
        case .placeMap: self = .placeMap
        case .settings: self = .settings
        }
    }

    var section: PadSection {
        switch self {
        case .wantToDo: return .category(.wantToDo)
        case .wantToGet: return .category(.wantToGet)
        case .wantToGo: return .category(.wantToGo)
        case .finished: return .finished
        case .badges: return .badges
        case .placeMap: return .placeMap
        case .settings: return .settings
        }
    }

    var category: Category? {
        if case .category(let category) = section { return category }
        return nil
    }

    /// `sidebar_item` 로그의 type (트래킹 이벤트 표)
    var logType: String {
        switch self {
        case .wantToDo, .wantToGet, .wantToGo: return "category"
        case .finished: return "finished"
        case .badges: return "badge"
        case .placeMap: return "map"
        case .settings: return "settings"
        }
    }
}

extension PadRootViewModel {
    enum Action: Equatable {
        /// 아이패드 레이아웃이 처음 보일 때. 가로면 사이드바까지 3단, 세로면 사이드바가 접혀 2단 (TC-16)
        case onAppear(isLandscape: Bool)
        /// 위시가 바뀌었을 때 사이드바 개수를 다시 센다
        case reloadCounts
        case tapSidebar(PadSidebarItem)
        /// 사이드바 아래 "뭐 하고 싶어요?" → 카테고리 팝오버
        case tapWrite
        case selectWriteCategory(Category)
        case dismissWritePicker
    }

    struct State: Equatable {
        /// 카테고리별 아직 이루지 않은 위시 수
        var counts: [Category: Int] = [:]
        var isWritePickerPresented = false
    }

    struct Dependency {
        let router: AppRouter
        let wishRepository: WishRepository
        let logManager: LogManagerProtocol

        init(
            router: AppRouter,
            wishRepository: WishRepository = WishRepositoryImpl(),
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.router = router
            self.wishRepository = wishRepository
            self.logManager = logManager
        }
    }
}

/// 아이패드 사이드바 입력·개수·노출 로그 (GH-99 R-4, TC-2·TC-15·TC-16)
@Observable
final class PadRootViewModel {
    let screenName: ScreenName = .home
    private(set) var state = State()

    private let dependency: Dependency
    private var didSendLayoutImpression = false

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    var selectedItem: PadSidebarItem {
        PadSidebarItem(section: dependency.router.padSection)
    }

    /// 카테고리 팝오버에서 선택 테두리를 둘 카테고리 = 마지막으로 본 카테고리 (GH-64 R-8)
    var highlightedCategory: Category {
        dependency.router.homeCategory
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear(let isLandscape):
            reloadCounts()
            sendLayoutImpression(isLandscape: isLandscape)

        case .reloadCounts:
            reloadCounts()

        case .tapSidebar(let item):
            var parameters: [ParameterName: Any] = [.type: item.logType]
            if let category = item.category {
                parameters[.category] = category.rawValue
            }
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .sidebarItem,
                extraParameters: parameters
            ))
            dependency.router.selectPadSection(item.section)

        case .tapWrite:
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: screenName,
                objectType: .button,
                objectId: .tabWrite
            ))
            state.isWritePickerPresented = true

        case .selectWriteCategory(let category):
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: .writeCategorySheet,
                objectType: .button,
                objectId: .writeCategory,
                extraParameters: [.category: category.rawValue]
            ))
            state.isWritePickerPresented = false
            dependency.router.writeCategory = category

        case .dismissWritePicker:
            state.isWritePickerPresented = false
        }
    }

    private func reloadCounts() {
        var counts: [Category: Int] = [:]
        for category in [Category.wantToDo, .wantToGet, .wantToGo] {
            counts[category] = dependency.wishRepository.fetchNotFinishCount(category: category)
        }
        state.counts = counts
    }

    /// 패드 사용자 수를 보려고 실행마다 한 번만 보낸다
    private func sendLayoutImpression(isLandscape: Bool) {
        guard !didSendLayoutImpression else { return }
        didSendLayoutImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .card,
            objectId: .padLayout,
            extraParameters: [.type: isLandscape ? "three_column" : "two_column"]
        ))
    }
}
