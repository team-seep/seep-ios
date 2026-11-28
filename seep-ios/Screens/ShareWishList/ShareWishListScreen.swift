import SwiftUI

/// 골라서 보내기 미리보기 (GH-125 R-2). 홈 선택 모드 "n개 보내기"에서 `.seepFullScreenCover`로 열린다.
/// ✕ · 헤드라인 "이렇게 한 장으로 / **보낼게요**" · 카드 미리보기 · 토글 2개 · 하단 "보내기"
struct ShareWishListScreen: View {
    @State private var viewModel: ShareWishListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var cardWidth: CGFloat = 0
    @State private var shareImage: Image?

    private let horizontalInset: CGFloat = 20

    init(presentation: ShareWishListPresentation) {
        _viewModel = State(initialValue: ShareWishListViewModel(config: .init(
            category: presentation.category,
            wishes: presentation.wishes
        )))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            closeBar
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HeadlineText(text: Strings.ShareWishList.headline, boldPart: Strings.ShareWishList.headlineBold)
                        .padding(.leading, 22)
                    // 보내는 이미지와 같게 화면 모드와 상관없이 라이트로 보인다
                    ShareWishListCardView(card: viewModel.state.card)
                        .environment(\.colorScheme, .light)
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cardWidth = $0 }
                        .padding(.horizontal, horizontalInset)
                        .padding(.top, 20)
                    toggles
                        .padding(.horizontal, horizontalInset)
                        .padding(.top, 16)
                }
                // 하단 버튼에 가리지 않도록 아래 여백을 둔다
                .padding(.bottom, 50 + 24 + 16)
                .frame(maxWidth: SeepLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            sendButton
                .padding(.bottom, 24)
        }
        .background(Color.gray2.ignoresSafeArea())
        .trackScreen(viewModel.screenName)
        .onAppear { renderShareImage() }
        .onChange(of: viewModel.state.card) { _, _ in renderShareImage() }
        .onChange(of: cardWidth) { _, _ in renderShareImage() }
        .onChange(of: viewModel.route) { _, route in handle(route) }
    }

    private var closeBar: some View {
        HStack {
            Spacer()
            Button {
                viewModel.send(.tapClose)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.gray5)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Strings.ShareWishList.close))
        }
        .padding(.top, 4)
        .padding(.trailing, 12)
    }

    private var toggles: some View {
        VStack(spacing: 0) {
            toggleRow(
                title: Strings.ShareWishList.ddayToggle,
                detail: Strings.ShareWishList.ddayToggleDetail,
                isOn: Binding(
                    get: { viewModel.state.includesDday },
                    set: { viewModel.send(.setIncludesDday($0)) }
                )
            )
            if viewModel.state.isLinkToggleVisible {
                toggleRow(
                    title: Strings.ShareWishList.linkToggle,
                    detail: Strings.ShareWishList.linkToggleDetail,
                    isOn: Binding(
                        get: { viewModel.state.includesLink },
                        set: { viewModel.send(.setIncludesLink($0)) }
                    )
                )
            }
        }
    }

    private func toggleRow(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appleSemiBold(size: 15))
                    .foregroundStyle(Color.gray5)
                Text(detail)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
            }
        }
        .tint(Color.tennisGreen)
        .frame(minHeight: 52)
    }

    @ViewBuilder
    private var sendButton: some View {
        let label = Text(Strings.ShareWishList.send)
            .font(.appleExtraBold(size: 17))
            .foregroundStyle(Color.onAccent)
            .frame(width: 240, height: 50)
            .background(Color.tennisGreen, in: Capsule())
        if let shareImage {
            ShareLink(
                item: shareImage,
                message: Text(verbatim: viewModel.state.text),
                preview: SharePreview(viewModel.state.card.categoryTitle, image: shareImage)
            ) {
                label
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { viewModel.send(.didTapSend) })
        } else {
            label.opacity(0.6)
        }
    }

    /// 카드를 그린 이미지를 미리 만들어 둔다. `ShareLink`는 누르는 순간 항목이 있어야 한다
    private func renderShareImage() {
        guard cardWidth > 0 else { return }
        shareImage = ShareWishListImageRenderer.render(card: viewModel.state.card, cardWidth: cardWidth)
    }

    private func handle(_ route: ShareWishListViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .dismiss:
            dismiss()
        }
        viewModel.send(.routeHandled)
    }
}
