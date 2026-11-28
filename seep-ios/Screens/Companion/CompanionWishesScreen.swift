import SwiftUI

/// 사람별 모아보기 (GH-122 R-5 ~ R-7). "엄마랑 하고 싶은 것 / 3개 남았어요!" + 남은 싶 + 같이 이룬 것 + 하단 적기 버튼
struct CompanionWishesScreen: View {
    let personId: String

    @State private var viewModel: CompanionWishesViewModel

    init(personId: String) {
        self.personId = personId
        _viewModel = State(initialValue: CompanionWishesViewModel(config: .init(personId: personId)))
    }

    var body: some View {
        CompanionWishesContent(viewModel: viewModel)
    }
}

private enum CompanionWishesLayout {
    static let horizontalInset: CGFloat = 20
    /// 공유 이미지 카드 폭(pt). 화면 폭과 상관없이 같은 모양으로 만든다
    static let shareCardWidth: CGFloat = 360
}

private struct CompanionWishesContent: View {
    let viewModel: CompanionWishesViewModel

    @Environment(AppRouter.self) private var router
    @State private var shareImage: Image?

    private var state: CompanionWishesViewModel.State { viewModel.state }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                CompanionHeadline(state: state)
                    .padding(.top, 12)
                Text(Strings.Companion.Wishes.categories)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .padding(.top, 20)
                remainingList
                    .padding(.top, 12)
                if !state.finished.isEmpty {
                    Text(verbatim: state.finishedTitle)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray4)
                        .padding(.top, 28)
                    rows(state.finished)
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, CompanionWishesLayout.horizontalInset)
            .padding(.bottom, 24)
            .frame(maxWidth: SeepLayout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.gray2.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if state.person != nil {
                SeepCTA(title: state.writeTitle) {
                    viewModel.send(.tapWrite)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { shareButton }
        }
        .trackScreen(viewModel.screenName)
        .onAppear { reload() }
        // 모아보기에서 연 작성 화면에서 저장하면 여기 머문다 — 방금 적은 싶을 다시 읽는다 (R-6)
        .onChange(of: router.wishesChangedToken) { _, _ in reload() }
        .onChange(of: state) { _, _ in renderShareImage() }
        .onChange(of: viewModel.route) { _, route in handle(route) }
    }

    @ViewBuilder
    private var remainingList: some View {
        if state.remaining.isEmpty {
            Text(Strings.Companion.Wishes.empty)
                .font(.appleMedium(size: 15))
                .foregroundStyle(Color.gray4)
                .frame(maxWidth: .infinity, minHeight: 70)
                .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        } else {
            rows(state.remaining)
        }
    }

    private func rows(_ wishes: [Wish]) -> some View {
        VStack(spacing: 10) {
            ForEach(wishes, id: \.id) { wish in
                // 이 화면에서는 이룸을 바꾸지 않는다 — 체크 원을 눌러도 상세로 간다
                Button {
                    viewModel.send(.tapWish(id: wish.id))
                } label: {
                    WishRow(
                        model: WishRowModel(wish: wish),
                        farFutureText: Strings.homeInFarFurture,
                        noDateText: Strings.homeNoDeanline,
                        onToggle: { viewModel.send(.tapWish(id: wish.id)) }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let shareImage {
            ShareLink(
                item: shareImage,
                preview: SharePreview(state.headline, image: shareImage)
            ) {
                Text(Strings.Companion.Wishes.share)
                    .foregroundStyle(Color.seepBlue)
            }
            .simultaneousGesture(TapGesture().onEnded { viewModel.send(.tapShare) })
        }
    }

    private func reload() {
        viewModel.send(.onAppear)
        // 위시는 id 로만 같음을 보므로 제목만 바뀐 경우를 위해 다시 읽을 때마다 그린다
        renderShareImage()
    }

    /// 남은 싶 카드를 미리 그려 둔다. `ShareLink`는 누르는 순간 항목이 있어야 한다
    private func renderShareImage() {
        guard state.person != nil else { return }
        shareImage = CompanionShareImageRenderer.render(state: state, width: CompanionWishesLayout.shareCardWidth)
    }

    private func handle(_ route: CompanionWishesViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .wishDetail(let id, let isFinished):
            router.push(.wishDetail(id: id, isFinished: isFinished))
        case .write(let person):
            router.openCompanionWrite(with: person)
        }
        viewModel.send(.routeHandled)
    }
}

/// "엄마랑 하고 싶은 것" (Light) / "3개 남았어요!" (Bold, 개수는 tennis-green)
private struct CompanionHeadline: View {
    let state: CompanionWishesViewModel.State
    var size: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: state.headline)
                .font(.appleLight(size: size))
            remainingText
                .font(.appleBold(size: size))
        }
        .foregroundStyle(Color.gray5)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private var remainingText: Text {
        let text = state.remainingText
        guard let range = text.range(of: state.remainingHighlight) else { return Text(verbatim: text) }
        return Text(verbatim: String(text[..<range.lowerBound]))
            + Text(verbatim: state.remainingHighlight).foregroundStyle(Color.tennisGreen)
            + Text(verbatim: String(text[range.upperBound...]))
    }
}

/// 공유 이미지 카드: 헤드라인 + 남은 싶 목록 (R-7). 화면 모드와 상관없이 라이트로 그린다
private struct CompanionShareCard: View {
    let state: CompanionWishesViewModel.State

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompanionHeadline(state: state, size: 24)
            Text(Strings.Companion.Wishes.categories)
                .font(.appleMedium(size: 13))
                .foregroundStyle(Color.gray4)
                .padding(.top, 16)
            VStack(spacing: 8) {
                ForEach(state.remaining, id: \.id) { wish in
                    HStack(spacing: 12) {
                        Text(verbatim: wish.emoji)
                            .font(.system(size: 26))
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(verbatim: wish.title)
                                .font(.appleSemiBold(size: 15))
                                .foregroundStyle(Color.gray5)
                                .lineLimit(1)
                            DdayBadge(
                                style: DdayBadgeStyle(endDate: wish.endDate),
                                farFutureText: Strings.homeInFarFurture,
                                noDateText: Strings.homeNoDeanline
                            )
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 62)
                    .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 12)
        }
        .padding(24)
        .background(Color.gray2)
    }
}

enum CompanionShareImageRenderer {
    static let scale: CGFloat = 3

    @MainActor
    static func render(state: CompanionWishesViewModel.State, width: CGFloat) -> Image? {
        let renderer = ImageRenderer(content: CompanionShareCard(state: state)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.colorScheme, .light))
        renderer.scale = scale
        renderer.isOpaque = true
        guard let cgImage = renderer.cgImage else { return nil }
        return Image(decorative: cgImage, scale: scale)
    }
}
