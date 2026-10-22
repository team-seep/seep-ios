import Foundation
import Observation

/// 탭 바에 그리는 항목. 적기는 탭으로 그리지만 화면을 바꾸지 않고 시트를 띄운다 (R-6)
enum MainTabItem: Hashable, CaseIterable {
    case wish
    case finished
    case write
    case settings
}

extension MainTabViewModel {
    enum Action: Equatable {
        case tapTab(MainTabItem)
        case selectWriteCategory(Category)
        case dismissWriteSheet
    }

    struct State: Equatable {
        var isWriteSheetPresented = false
    }

    struct Dependency {
        let router: AppRouter
        let logManager: LogManagerProtocol

        init(router: AppRouter, logManager: LogManagerProtocol = LogManager.shared) {
            self.router = router
            self.logManager = logManager
        }
    }
}

/// 탭 바 입력과 적기 시트 (GH-64 R-1 ~ R-11)
@Observable
final class MainTabViewModel {
    private(set) var state = State()

    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    /// 적기 시트에서 선택 테두리를 둘 카테고리 = 싶 탭에서 마지막으로 고른 카테고리 (R-8)
    var highlightedCategory: Category {
        dependency.router.homeCategory
    }

    func send(_ action: Action) {
        switch action {
        case .tapTab(let item):
            sendTabClickLog(item)
            switch item {
            case .wish:
                dependency.router.select(.wish)
            case .finished:
                dependency.router.select(.finished)
            case .settings:
                dependency.router.select(.settings)
            case .write:
                state.isWriteSheetPresented = true
            }

        case .selectWriteCategory(let category):
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: .writeCategorySheet,
                objectType: .button,
                objectId: .writeCategory,
                extraParameters: [.category: category.rawValue]
            ))
            state.isWriteSheetPresented = false
            dependency.router.writeCategory = category

        case .dismissWriteSheet:
            state.isWriteSheetPresented = false
        }
    }

    /// 지금 탭 화면 이름으로 보낸다 (트래킹 이벤트 표)
    private func sendTabClickLog(_ item: MainTabItem) {
        let objectId: LogObjectId
        switch item {
        case .wish: objectId = .tabWish
        case .finished: objectId = .tabFinished
        case .write: objectId = .tabWrite
        case .settings: objectId = .tabSettings
        }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: currentScreenName,
            objectType: .tab,
            objectId: objectId
        ))
    }

    private var currentScreenName: ScreenName {
        switch dependency.router.selectedTab {
        case .wish: return .home
        case .finished: return .finished
        case .settings: return .settings
        }
    }
}
