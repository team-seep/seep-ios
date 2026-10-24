import SwiftUI

/// 메인 탭(싶 · 이룬 싶 · 적기 · 설정). 탭마다 자기 `NavigationStack`을 갖고, 화면을 쌓으면 탭 바가 숨는다 (GH-64 R-1 ~ R-5)
struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: MainTabViewModel?

    var body: some View {
        @Bindable var router = router

        // 시스템 탭 바를 써서 iOS 26 이상에서는 리퀴드 글래스로 그린다. 화면을 쌓으면 탭 바가 숨는다 (`seepDestinations`)
        TabView(selection: tabSelection) {
            Tab(value: MainTabItem.wish) {
                NavigationStack(path: $router.wishPath) {
                    WishTabRootView()
                        .seepDestinations()
                }
            } label: {
                Label(Strings.MainTab.wish, systemImage: "list.bullet.rectangle")
            }
            Tab(value: MainTabItem.finished) {
                NavigationStack(path: $router.finishedPath) {
                    FinishedTabRootView()
                        .seepDestinations()
                }
            } label: {
                Label(Strings.MainTab.finished, systemImage: "checkmark.circle")
            }
            .badge(router.showsFinishedDot ? Text(verbatim: "") : nil)
            .accessibilityValue(router.showsFinishedDot ? Text(Strings.MainTab.finishedDotAccessibility) : Text(verbatim: ""))
            // 적기는 화면이 없다. 고르면 `tabSelection`이 탭을 바꾸지 않고 시트를 띄운다 (R-6)
            Tab(value: MainTabItem.write) {
                Color.gray2
            } label: {
                Label(Strings.MainTab.write, systemImage: "plus.circle.fill")
            }
            Tab(value: MainTabItem.settings) {
                NavigationStack(path: $router.settingsPath) {
                    SettingsTabRootView()
                        .seepDestinations()
                }
            } label: {
                Label(Strings.MainTab.settings, systemImage: "gearshape")
            }
        }
        .tint(Color.seepBlue)
        .sensoryFeedback(.selection, trigger: router.selectedTab)
        .seepSheet(isPresented: writeSheetBinding) {
            if let viewModel {
                WriteCategorySheet(
                    highlightedCategory: viewModel.highlightedCategory,
                    onSelect: { viewModel.send(.selectWriteCategory($0)) }
                )
            }
        }
        .seepFullScreenCover(item: $router.writeCategory) { category in
            WishFormScreen(mode: .add(category), previousWishId: router.writePreviousWishId) { savedWish in
                router.writeCategory = nil
                if let savedWish {
                    router.wishesDidChange()
                    // 작성을 마치면 싶 탭으로 가서 그 카테고리를 보여준다 (R-9)
                    router.homeCategory = savedWish.category
                    router.select(.wish)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MainTabViewModel(dependency: .init(router: router))
            }
        }
    }

    /// 탭 선택은 모두 뷰모델을 거친다 — 같은 탭을 다시 누르면 맨 위로·루트로, 적기는 시트 (R-3, R-6)
    private var tabSelection: Binding<MainTabItem> {
        Binding(
            get: {
                switch router.selectedTab {
                case .wish: return .wish
                case .finished: return .finished
                case .settings: return .settings
                }
            },
            set: { item in viewModel?.send(.tapTab(item)) }
        )
    }

    private var writeSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.state.isWriteSheetPresented ?? false },
            set: { isPresented in
                if !isPresented { viewModel?.send(.dismissWriteSheet) }
            }
        )
    }
}
