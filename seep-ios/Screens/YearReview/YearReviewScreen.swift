import SwiftUI

/// 올해 이룬 싶 회고 화면 (GH-34 R-3~R-6, GH-64 TC-901~903).
/// 싶 탭 배너·이룬 싶 탭 카드에서 `.seepFullScreenCover`로 열린다. "모두 보기"는 이 화면 안 스택에 쌓는다
struct YearReviewScreen: View {
    let year: Int

    @State private var viewModel: YearReviewViewModel

    init(year: Int) {
        self.year = year
        _viewModel = State(initialValue: YearReviewViewModel(config: .init(year: year)))
    }

    var body: some View {
        NavigationStack {
            YearReviewContentView(viewModel: viewModel)
        }
    }
}

private struct YearReviewContentView: View {
    let viewModel: YearReviewViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showsList = false
    @State private var cardWidth: CGFloat = 0
    @State private var shareImage: Image?

    private let horizontalInset: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    if let summary = viewModel.state.summary {
                        YearReviewCard(summary: summary)
                            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cardWidth = $0 }
                    }
                    Button {
                        viewModel.send(.tapShowAll)
                    } label: {
                        Text(Strings.YearReview.showAll)
                            .font(.appleBold(size: 14))
                            .foregroundStyle(Color.seepBlue)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, horizontalInset)
                .padding(.top, 4)
                // 공유 버튼에 가리지 않도록 아래 여백을 둔다
                .padding(.bottom, 50 + 24 + 16)
                .frame(maxWidth: SeepLayout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            shareButton
                .padding(.bottom, 24)
        }
        .background(Color.gray2.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.send(.tapClose)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.gray5)
                }
                .accessibilityLabel(Text(Strings.YearReview.close))
            }
        }
        .trackScreen(viewModel.screenName)
        .navigationDestination(isPresented: $showsList) {
            YearReviewListScreen(year: viewModel.year)
                .seepPushedScreen()
        }
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: viewModel.state.summary) { _, _ in renderShareImage() }
        .onChange(of: cardWidth) { _, _ in renderShareImage() }
        .onChange(of: viewModel.route) { _, route in handle(route) }
    }

    @ViewBuilder
    private var shareButton: some View {
        let label = Text(Strings.YearReview.share)
            .font(.appleExtraBold(size: 17))
            .foregroundStyle(Color.onAccent)
            .padding(.horizontal, 36)
            .frame(height: 50)
            .background(Color.tennisGreen, in: Capsule())
        if let shareImage {
            ShareLink(
                item: shareImage,
                preview: SharePreview(Strings.YearReview.share, image: shareImage)
            ) {
                label
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { viewModel.send(.didTapShare) })
        } else {
            label.opacity(0.6)
        }
    }

    /// 카드를 그린 이미지를 미리 만들어 둔다. `ShareLink`는 누르는 순간 항목이 있어야 한다
    private func renderShareImage() {
        guard let summary = viewModel.state.summary, cardWidth > 0 else { return }
        shareImage = YearReviewImageRenderer.render(summary: summary, cardWidth: cardWidth)
    }

    private func handle(_ route: YearReviewViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .yearReviewList:
            showsList = true
        case .dismiss:
            dismiss()
        }
        viewModel.send(.routeHandled)
    }
}
