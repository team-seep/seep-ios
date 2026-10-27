import SwiftUI

/// 싶 탭 루트 — 홈 (R-12 ~ R-16, TC-101~). 라우터를 받아 홈 ViewModel 을 한 번만 만든다
struct WishTabRootView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HomeViewModel?
    @State private var noticeViewModel = MigrationNoticeViewModel()

    var body: some View {
        Group {
            if let viewModel {
                HomeView(viewModel: viewModel, noticeViewModel: noticeViewModel)
            } else {
                Color.gray2.ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(dependency: .init(router: router))
            }
        }
    }
}
