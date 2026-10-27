import SwiftUI

extension EnvironmentValues {
    /// 아이패드 목록 옆 상세 열 안인지. 상세가 스스로 닫힐 때 dismiss 대신 열을 비운다 (GH-99 R-5)
    @Entry var isPadDetailPane = false
}

/// 아이패드(regular) 루트: 사이드바 · 목록 · 상세 (GH-99 R-4 ~ R-7, R-10 ~ R-12).
/// 열마다 자기 내비게이션 바를 갖도록 시스템 3단 `NavigationSplitView`를 쓴다. 상세 열이 없는 항목(배지·지도, 고른 위시가 없는 그리드)은
/// 2단으로 바꿔 화면을 넓게 쓴다. 가로는 사이드바까지 보이고, 세로는 사이드바를 접는다(바 버튼으로 연다, R-6)
struct PadRootView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: PadRootViewModel?
    @State private var isLandscape = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if usesDetailColumn {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebar
                } content: {
                    PadContentColumn()
                        .navigationSplitViewColumnWidth(
                            min: PadLayout.contentMinWidth,
                            ideal: contentIdealWidth,
                            max: PadLayout.contentMaxWidth
                        )
                } detail: {
                    PadDetailColumn()
                }
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebar
                } detail: {
                    PadContentColumn()
                }
            }
        }
        .tint(Color.seepBlue)
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width > proxy.size.height
        } action: { isLandscape in
            self.isLandscape = isLandscape
            updateColumnVisibility()
        }
        .onChange(of: usesDetailColumn) { _, _ in
            updateColumnVisibility()
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PadRootViewModel(dependency: .init(router: router))
            }
            updateColumnVisibility()
            viewModel?.send(.onAppear(isLandscape: isLandscape))
        }
        .onChange(of: router.wishesChangedToken) { _, _ in
            viewModel?.send(.reloadCounts)
        }
        .modifier(WriteScreenPresenter())
    }

    @ViewBuilder
    private var sidebar: some View {
        if let viewModel {
            PadSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        }
    }

    /// 목록 옆 상세 열이 있는지. 리스트 보기는 늘, 그리드 보기는 위시를 골랐을 때만 (R-5, TC-7)
    private var usesDetailColumn: Bool {
        switch router.padSection {
        case .category:
            return !router.padHomeUsesGrid || router.padSelection != nil
        case .finished, .settings:
            return true
        case .badges, .placeMap:
            return false
        }
    }

    /// 그리드에서 상세를 열면 그리드는 3열이 들어가는 폭으로 줄어든다 (R-5)
    private var contentIdealWidth: CGFloat {
        if case .category = router.padSection, router.padHomeUsesGrid {
            return PadLayout.gridWithDetailWidth
        }
        return PadLayout.listIdealWidth
    }

    private func updateColumnVisibility() {
        if isLandscape {
            columnVisibility = .all
        } else {
            columnVisibility = usesDetailColumn ? .doubleColumn : .detailOnly
        }
    }
}

/// 사이드바에서 고른 항목의 목록 열. 항목마다 자기 `NavigationStack`을 갖는다
private struct PadContentColumn: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        switch router.padSection {
        case .category:
            NavigationStack(path: $router.wishPath) {
                WishTabRootView()
                    .seepDestinations()
            }
        case .finished:
            NavigationStack(path: $router.finishedPath) {
                FinishedTabRootView()
                    .seepDestinations()
            }
        case .badges:
            NavigationStack(path: $router.padSectionPath) {
                BadgeCollectionScreen()
                    .seepDestinations()
            }
        case .placeMap:
            NavigationStack(path: $router.padSectionPath) {
                PlaceMapScreen()
                    .seepDestinations()
            }
        case .settings:
            NavigationStack(path: $router.settingsPath) {
                SettingsTabRootView()
                    .seepDestinations()
            }
        }
    }
}

/// 상세 열: 홈·이룬 싶은 고른 위시 문서, 설정은 하위 화면 (R-5, R-7, R-11). 없으면 안내
private struct PadDetailColumn: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        if router.padSection == .settings {
            if let destination = router.padSettingsDetail {
                NavigationStack {
                    DestinationView(destination: destination)
                }
                .id(destination)
            } else {
                PadEmptyColumn(message: Strings.Pad.SettingsDetail.empty)
            }
        } else if let selection = router.padSelection {
            NavigationStack {
                WishDetailScreen(wishId: selection.id, isFinished: selection.isFinished)
            }
            // 다른 위시를 고르면 새 문서로 연다(상세 ViewModel 은 위시마다 하나)
            .id(selection)
            .environment(\.isPadDetailPane, true)
        } else {
            PadEmptyColumn(message: Strings.Pad.Detail.empty)
        }
    }
}

/// 아이패드 목록 열 폭
enum PadLayout {
    static let contentMinWidth: CGFloat = 320
    static let listIdealWidth: CGFloat = 380
    static let contentMaxWidth: CGFloat = 640
    /// 그리드 3열(셀 폭 약 180pt) + 좌우 여백
    static let gridWithDetailWidth: CGFloat = 600
}

private struct PadEmptyColumn: View {
    let message: String

    var body: some View {
        Text(verbatim: message)
            .font(.appleMedium(size: 15))
            .foregroundStyle(Color.gray4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray1.ignoresSafeArea())
    }
}

extension View {
    /// 아이패드 상세 열에 열린 셀: seep-blue 2pt 테두리 (GH-99 R-5, TC-3). 셀 모양(라운드 12)에 맞춘다
    func padSelectionBorder(isSelected: Bool) -> some View {
        overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.seepBlue, lineWidth: 2)
                    .allowsHitTesting(false)
            }
        }
    }
}
