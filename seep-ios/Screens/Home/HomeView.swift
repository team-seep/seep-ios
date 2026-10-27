import SwiftUI

/// 싶 탭(홈). 헤드라인 → 연말 회고 배너 → [카테고리 탭 · 정렬/검색/보기] 고정 헤더 → 잠든 위시 카드 + 위시 리스트·그리드 (GH-64 R-12 ~ R-16)
struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    /// 1회 이전 실패 안내 카드 (GH-96). 미리보기·테스트에서는 없어도 된다
    var noticeViewModel: MigrationNoticeViewModel?
    @Environment(AppRouter.self) private var router
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.openURL) private var openURL

    private static let topAnchorId = "home-top"

    var body: some View {
        Group {
            if viewModel.state.isReordering {
                HomeReorderView(viewModel: viewModel)
            } else if viewModel.state.isSelecting {
                HomeSelectionView(viewModel: viewModel)
            } else {
                homeList
            }
        }
        // 순서 바꾸기 중에는 탭 바를 숨겨 작성·다른 탭으로 빠지지 않게 한다 ("완료"로만 나간다, GH-73 R-5)
        // 선택 모드도 탭 바를 숨긴다 (GH-86 R-3)
        .toolbarVisibility(viewModel.state.isReordering || viewModel.state.isSelecting ? .hidden : .automatic, for: .tabBar)
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.isReordering)
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.isSelecting)
        .modifier(HomeViewEvents(viewModel: viewModel))
        .onChange(of: viewModel.state.viewType, initial: true) { _, viewType in
            router.padHomeUsesGrid = viewType == .grid
        }
        .onAppear { noticeViewModel?.send(.onAppear) }
        .onChange(of: noticeViewModel?.route) { _, route in
            handleNoticeRoute(route)
        }
    }

    // MARK: 이전 실패 카드 Route (GH-96)
    private func handleNoticeRoute(_ route: MigrationNoticeViewModel.Route?) {
        guard let route, let noticeViewModel else { return }
        switch route {
        case .restored(let toast):
            router.wishesDidChange()
            if let toast { toastCenter.show(toast) }
        case .toast(let message):
            toastCenter.show(message)
        case .openURL(let url):
            openURL(url)
        }
        noticeViewModel.send(.routeHandled)
    }

    private var homeList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    HomeOverviewView(category: viewModel.state.category, count: viewModel.state.notFinishedCount)
                        .id(Self.topAnchorId)

                    if let noticeViewModel, noticeViewModel.state.problem != nil {
                        HomeMigrationNoticeCardView(
                            state: noticeViewModel.state,
                            onContact: { noticeViewModel.send(.tapContact) },
                            onRetry: { noticeViewModel.send(.tapRetry) }
                        )
                        .padding(.horizontal, HomeLayout.horizontalInset)
                        .padding(.bottom, 16)
                    }

                    if let banner = viewModel.state.yearReviewBanner {
                        HomeYearReviewBannerView(
                            banner: banner,
                            onTap: { viewModel.send(.tapYearReviewBanner) },
                            onClose: { viewModel.send(.closeYearReviewBanner) }
                        )
                        .padding(.horizontal, HomeLayout.horizontalInset)
                        .padding(.bottom, 16)
                    }

                    Section {
                        content
                            .padding(.horizontal, HomeLayout.horizontalInset)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    } header: {
                        filterHeader
                    }
                }
                // 아이패드는 열 폭이 곧 기둥이라 가두지 않는다. 그리드가 폭을 채워 4열 이상이 된다 (GH-99 TC-7)
                .frame(maxWidth: router.isRegularLayout ? .infinity : HomeLayout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Color.gray2)
            .onChange(of: router.scrollToTopToken[.wish]) { _, _ in
                withAnimation { proxy.scrollTo(Self.topAnchorId, anchor: .top) }
            }
        }
        .background(Color.gray2.ignoresSafeArea())
    }

    private var filterHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 아이패드는 사이드바가 카테고리를 고른다 (GH-99 R-4)
            if !router.isRegularLayout {
                HomeCategoryTabs(selected: viewModel.state.category) { viewModel.send(.selectCategory($0)) }
                    .padding(.horizontal, 12)
            }
            HomeFilterBar(
                sortOrder: viewModel.state.sortOrder,
                viewType: viewModel.state.viewType,
                isPlaceMapVisible: viewModel.state.isPlaceMapVisible,
                isReorderVisible: viewModel.state.isReorderButtonVisible,
                onTapReorder: { viewModel.send(.tapReorder) },
                isSelectVisible: viewModel.state.isSelectButtonVisible,
                onTapSelect: { viewModel.send(.tapSelect) },
                onTapSort: { viewModel.send(.tapSortOrder) },
                onTapPlaceMap: { viewModel.send(.tapPlaceMap) },
                onTapSearch: { viewModel.send(.tapSearch) },
                onToggleViewType: { viewModel.send(.toggleViewType) },
                sortPopover: router.isRegularLayout ? sortPopover : nil
            )
            .padding(.horizontal, HomeLayout.horizontalInset - 12)
        }
        .padding(.top, 6)
        .background(Color.gray2)
        .overlay(alignment: .bottom) {
            // 목록이 고정 헤더 밑으로 들어갈 때 끊기지 않게 바탕색 → 투명 페이드 10pt
            LinearGradient(colors: [Color.gray2, Color.gray2.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: 10)
                .offset(y: 10)
                .allowsHitTesting(false)
        }
    }

    /// 아이패드는 정렬 버튼에 붙은 팝오버로 고른다 (GH-99 R-9, TC-8)
    private var sortPopover: HomeFilterBar.SortPopover {
        HomeFilterBar.SortPopover(
            isPresented: Binding(
                get: { viewModel.state.sheet == .sortOrder },
                set: { isPresented in
                    if !isPresented, viewModel.state.sheet == .sortOrder { viewModel.send(.sheetDismissed) }
                }
            ),
            onSelect: { viewModel.send(.selectSortOrder($0)) }
        )
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isEmpty {
            HomeEmptyView()
        } else {
            VStack(spacing: viewModel.state.viewType == .list ? HomeLayout.listSpacing : HomeGridLayout.spacing) {
                if let card = viewModel.state.sleepingWishCard {
                    HomeSleepingWishCardView(
                        card: card,
                        onRelease: { viewModel.send(.tapReleaseSleepingWish(card.wish)) },
                        onKeep: { viewModel.send(.keepSleepingWish(card.wish)) }
                    )
                }
                switch viewModel.state.viewType {
                case .list:
                    ForEach(viewModel.state.items) { item in
                        HomeWishRow(item: item) { viewModel.send(.tapFinish(item.wish)) }
                            .padSelectionBorder(isSelected: router.padSelection?.id == item.id)
                            .onTapGesture { viewModel.send(.tapWish(item.wish)) }
                            .modifier(HomeWishMenu(item: item, viewModel: viewModel))
                    }
                case .grid:
                    HomeWishGrid(items: viewModel.state.items, viewModel: viewModel)
                }
            }
        }
    }
}

/// 홈 화면 수명주기·시트·알럿. 순서 바꾸기 모드와 일반 목록이 같이 쓴다
private struct HomeViewEvents: ViewModifier {
    @Bindable var viewModel: HomeViewModel
    @Environment(AppRouter.self) private var router
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            // 아이패드는 바에 사이드바 버튼이 있어 바를 남긴다 (GH-99 R-6)
            .toolbarVisibility(router.isRegularLayout ? .automatic : .hidden, for: .navigationBar)
            .trackScreen(viewModel.screenName)
            .onAppear {
                viewModel.send(.onAppear)
                viewModel.send(.syncWidgetChanges)
            }
            .onChange(of: scenePhase) { _, phase in
                // 앱이 다시 활성화될 때 싶 탭이 보이면 위젯 기록을 반영한다 (GH-48 R-7, R-8)
                if phase == .active, router.selectedTab == .wish, router.wishPath.isEmpty {
                    viewModel.send(.syncWidgetChanges)
                }
            }
            .onChange(of: router.selectedTab) { _, tab in
                // 다른 탭에 있다가 싶 탭으로 돌아오면 위젯 기록을 반영한다 (R-16)
                if tab == .wish { viewModel.send(.syncWidgetChanges) }
            }
            .onChange(of: router.wishesChangedToken) { _, _ in
                viewModel.send(.onAppear)
            }
            .onChange(of: router.homeCategory) { _, category in
                // 작성을 마치면 그 카테고리를 보여준다 (R-9)
                if category != viewModel.state.category { viewModel.send(.selectCategory(category)) }
            }
            .onChange(of: viewModel.state.toast) { _, toast in
                if let toast { toastCenter.show(toast.message) }
            }
            .seepSheet(item: sheetBinding) { sheet in
                switch sheet {
                case .sortOrder:
                    SortOrderSheet(selected: viewModel.state.sortOrder) { viewModel.send(.selectSortOrder($0)) }
                case .finishNote(let finishNoteViewModel):
                    FinishNoteSheet(viewModel: finishNoteViewModel)
                case .badgeCelebration(let celebrationViewModel):
                    BadgeCelebrationSheet(viewModel: celebrationViewModel)
                }
            }
            .seepFullScreenCover(item: yearReviewBinding) { presentation in
                YearReviewScreen(year: presentation.year)
            }
            .alert(
                Strings.Home.SleepingWish.Alert.title,
                isPresented: releaseAlertBinding,
                presenting: viewModel.state.releaseAlertWish,
                actions: { wish in
                    Button(Strings.Home.SleepingWish.Alert.cancel, role: .cancel) {
                        viewModel.send(.cancelReleaseSleepingWish)
                    }
                    Button(Strings.Home.SleepingWish.Alert.release, role: .destructive) {
                        viewModel.send(.confirmReleaseSleepingWish(wish))
                    }
                },
                message: { _ in Text(Strings.Home.SleepingWish.Alert.message) }
            )
            .alert(
                Strings.Home.Select.DeleteAlert.titleFormat(viewModel.state.deleteConfirmCount ?? 0),
                isPresented: deleteConfirmBinding,
                actions: {
                    Button(Strings.Home.Select.cancel, role: .cancel) {
                        viewModel.send(.cancelDeleteSelected)
                    }
                    Button(Strings.Home.Select.DeleteAlert.confirm, role: .destructive) {
                        viewModel.send(.confirmDeleteSelected)
                    }
                },
                message: { Text(Strings.Home.Select.DeleteAlert.message) }
            )
            .alert(
                viewModel.state.errorMessage ?? "",
                isPresented: errorAlertBinding,
                actions: {
                    Button(Strings.Home.ErrorAlert.confirm, role: .cancel) {
                        viewModel.send(.errorAlertDismissed)
                    }
                }
            )
    }

    private var sheetBinding: Binding<HomeSheet?> {
        Binding(
            // 아이패드의 정렬은 시트가 아니라 정렬 버튼의 팝오버다 (GH-99 R-9)
            get: { router.isRegularLayout && viewModel.state.sheet == .sortOrder ? nil : viewModel.state.sheet },
            set: { newValue in
                if newValue == nil, viewModel.state.sheet != nil { viewModel.send(.sheetDismissed) }
            }
        )
    }

    private var yearReviewBinding: Binding<YearReviewPresentation?> {
        Binding(
            get: { viewModel.state.yearReviewPresentation },
            set: { newValue in
                if newValue == nil { viewModel.send(.yearReviewDismissed) }
            }
        )
    }

    private var releaseAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.releaseAlertWish != nil },
            set: { isPresented in
                if !isPresented, viewModel.state.releaseAlertWish != nil { viewModel.send(.cancelReleaseSleepingWish) }
            }
        )
    }

    private var deleteConfirmBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.deleteConfirmCount != nil },
            set: { isPresented in
                if !isPresented, viewModel.state.deleteConfirmCount != nil { viewModel.send(.cancelDeleteSelected) }
            }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.errorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.send(.errorAlertDismissed) }
            }
        )
    }
}

/// 그리드 보기: 열 수는 콘텐츠 폭 기준 (`HomeGridLayout`)
private struct HomeWishGrid: View {
    let items: [HomeWishItem]
    let viewModel: HomeViewModel
    @Environment(AppRouter.self) private var router
    @State private var availableWidth: CGFloat = 0

    var body: some View {
        let columnCount = HomeGridLayout.columnCount(availableWidth: availableWidth)
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: HomeGridLayout.spacing), count: columnCount),
            spacing: HomeGridLayout.spacing
        ) {
            ForEach(items) { item in
                HomeWishTile(
                    item: item,
                    thumbnail: viewModel.thumbnails[item.id],
                    onToggle: { viewModel.send(.tapFinish(item.wish)) },
                    onNeedThumbnail: { viewModel.send(.loadThumbnail(wishId: item.id, maxPixelSize: $0)) }
                )
                .padSelectionBorder(isSelected: router.padSelection?.id == item.id)
                .onTapGesture { viewModel.send(.tapWish(item.wish)) }
                .modifier(HomeWishMenu(item: item, viewModel: viewModel))
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
    }
}

/// 길게 누르면 뜨는 메뉴: 맨 위에 고정/고정 해제 · 삭제 (GH-33 R-2). 완료 흐름 중인 위시는 메뉴가 없다
private struct HomeWishMenu: ViewModifier {
    let item: HomeWishItem
    let viewModel: HomeViewModel

    func body(content: Content) -> some View {
        if item.canShowPinMenu {
            content.contextMenu {
                Button {
                    viewModel.send(.tapPinMenu(item.wish))
                } label: {
                    Label(
                        item.isPinned ? Strings.Home.Pin.unpin : Strings.Home.Pin.pin,
                        systemImage: item.isPinned ? "pin.slash" : "pin"
                    )
                }
                Button(role: .destructive) {
                    viewModel.send(.delete(item.wish))
                } label: {
                    Label(Strings.Home.delete, systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
}
