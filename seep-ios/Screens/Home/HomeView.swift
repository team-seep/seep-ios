import SwiftUI

/// 싶 탭(홈). 헤드라인 → 연말 회고 배너 → [카테고리 탭 · 정렬/검색/보기] 고정 헤더 → 잠든 위시 카드 + 위시 리스트·그리드 (GH-64 R-12 ~ R-16)
struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(AppRouter.self) private var router
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.scenePhase) private var scenePhase

    private static let topAnchorId = "home-top"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    HomeOverviewView(category: viewModel.state.category, count: viewModel.state.notFinishedCount)
                        .id(Self.topAnchorId)

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
                .frame(maxWidth: HomeLayout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Color.gray2)
            .onChange(of: router.scrollToTopToken[.wish]) { _, _ in
                withAnimation { proxy.scrollTo(Self.topAnchorId, anchor: .top) }
            }
        }
        .background(Color.gray2.ignoresSafeArea())
        .toolbarVisibility(.hidden, for: .navigationBar)
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
            viewModel.state.errorMessage ?? "",
            isPresented: errorAlertBinding,
            actions: {
                Button(Strings.Home.ErrorAlert.confirm, role: .cancel) {
                    viewModel.send(.errorAlertDismissed)
                }
            }
        )
    }

    private var filterHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HomeCategoryTabs(selected: viewModel.state.category) { viewModel.send(.selectCategory($0)) }
            HomeFilterBar(
                sortOrder: viewModel.state.sortOrder,
                viewType: viewModel.state.viewType,
                isPlaceMapVisible: viewModel.state.isPlaceMapVisible,
                onTapSort: { viewModel.send(.tapSortOrder) },
                onTapPlaceMap: { viewModel.send(.tapPlaceMap) },
                onTapSearch: { viewModel.send(.tapSearch) },
                onToggleViewType: { viewModel.send(.toggleViewType) }
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
                            .onTapGesture { viewModel.send(.tapWish(item.wish)) }
                            .modifier(HomeWishMenu(item: item, viewModel: viewModel))
                    }
                case .grid:
                    HomeWishGrid(items: viewModel.state.items, viewModel: viewModel)
                }
            }
        }
    }

    private var sheetBinding: Binding<HomeSheet?> {
        Binding(
            get: { viewModel.state.sheet },
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
