import SwiftUI

/// 메인 탭(싶 · 이룬 싶 · 적기 · 설정). 탭마다 자기 `NavigationStack`을 갖고, 화면을 쌓으면 탭 바가 숨는다 (GH-64 R-1 ~ R-5)
struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: MainTabViewModel?

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab(value: MainTab.wish) {
                NavigationStack(path: $router.wishPath) {
                    WishTabRootView()
                        .seepDestinations()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: MainTab.finished) {
                NavigationStack(path: $router.finishedPath) {
                    FinishedTabRootView()
                        .seepDestinations()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: MainTab.settings) {
                NavigationStack(path: $router.settingsPath) {
                    SettingsTabRootView()
                        .seepDestinations()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        // 시스템 탭 바로는 적기(초록 원·선택 안 됨)를 그릴 수 없어 직접 그린 탭 바를 쓴다 (R-2)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if router.path(for: router.selectedTab).isEmpty, let viewModel {
                MainTabBar(
                    selectedTab: router.selectedTab,
                    showsFinishedDot: router.showsFinishedDot,
                    onTap: { viewModel.send(.tapTab($0)) }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .seepSheet(isPresented: writeSheetBinding) {
            if let viewModel {
                WriteCategorySheet(
                    highlightedCategory: viewModel.highlightedCategory,
                    onSelect: { viewModel.send(.selectWriteCategory($0)) }
                )
            }
        }
        .seepFullScreenCover(item: $router.writeCategory) { category in
            // 작성 화면은 P2에서 SwiftUI 로 옮긴다
            PendingScreen(title: Strings.MainTab.write + " · " + category.rawValue)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MainTabViewModel(dependency: .init(router: router))
            }
        }
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
