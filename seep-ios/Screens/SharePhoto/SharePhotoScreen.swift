import SwiftUI

/// 사진 공유 (TC-1201~1203). 상세 ⋯ 메뉴 "공유하기"에서 `.seepFullScreenCover`로 띄운다.
/// 위시를 카드로 꾸며(이모지 또는 앨범 사진 바탕, 두 번 탭해 글자색) 앨범에 저장하고, 저장하면 닫으며 토스트를 띄운다
struct SharePhotoScreen: View {
    let wish: Wish

    var body: some View {
        NavigationStack {
            SharePhotoContent(wish: wish, library: PhotoLibrary())
        }
    }
}

/// `PhotoLibraryProviding`을 받아 프리뷰·검증에서 앨범을 바꿔 끼울 수 있게 한다
struct SharePhotoContent: View {
    private let library: PhotoLibraryProviding
    @State private var viewModel: SharePhotoViewModel
    @State private var photo: CGImage?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.displayScale) private var displayScale
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?

    init(wish: Wish, library: PhotoLibraryProviding) {
        self.library = library
        _viewModel = State(initialValue: SharePhotoViewModel(
            config: .init(wish: wish),
            dependency: .init(photoLibrary: library)
        ))
    }

    var body: some View {
        GeometryReader { proxy in
            let bottomSafeArea = proxy.safeAreaInsets.bottom
            let cardSide = SharePhotoLayout.cardSide(containerSize: proxy.size, bottomSafeArea: bottomSafeArea)
            let listBottomInset = SharePhotoLayout.shareButtonArea(bottomSafeArea: 0)

            VStack(spacing: 0) {
                card(side: cardSide)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity)
                ShareTypeSwitch(selected: viewModel.state.shareType) { type in
                    viewModel.send(type == .emoji ? .tapEmojiTab : .tapPhotoTab)
                }
                Group {
                    switch viewModel.state.shareType {
                    case .emoji:
                        ShareEmojiGrid(bottomInset: listBottomInset) { emoji in
                            viewModel.send(.selectEmoji(emoji))
                        }
                    case .photo:
                        SharePhotoGrid(
                            photoIds: viewModel.state.photoIds,
                            selectedPhotoId: viewModel.state.selectedPhotoId,
                            bottomInset: listBottomInset,
                            library: library
                        ) { photoId in
                            viewModel.send(.selectPhoto(photoId))
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .overlay(alignment: .bottom) {
                SeepCTA(title: Strings.sharePhotoButton, isEnabled: !viewModel.state.isSaving) {
                    viewModel.send(.tapShare(pngData: renderCard(side: cardSide)))
                }
                .padding(.bottom, SharePhotoLayout.shareButtonBottomOffset)
            }
        }
        .background(Color.gray1)
        .navigationTitle(Strings.sharePhotoTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Text(Strings.sharePhotoDismiss)
                        .foregroundStyle(Color.gray5)
                }
            }
        }
        .trackScreen(viewModel.screenName)
        .onAppear { viewModel.send(.onAppear) }
        .task(id: viewModel.state.selectedPhotoId) {
            await loadSelectedPhoto()
        }
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
        .alert(
            alertMessage ?? "",
            isPresented: alertBinding,
            actions: { alertActions },
            message: { EmptyView() }
        )
    }

    // MARK: Subviews

    private func card(side: CGFloat) -> some View {
        ShareCardView(state: viewModel.state, side: side, photo: photo)
            .overlay {
                if viewModel.state.isTooltipVisible {
                    ShareTooltip {
                        viewModel.send(.tooltipDidDisappear)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                viewModel.send(.doubleTapCard)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(Strings.SharePhoto.cardAccessibility))
            .accessibilityAction { viewModel.send(.doubleTapCard) }
    }

    // MARK: Render · Load

    /// 화면에 보이는 카드를 그대로 그려 PNG 로 만든다
    @MainActor
    private func renderCard(side: CGFloat) -> Data? {
        let renderer = ImageRenderer(content: ShareCardView(state: viewModel.state, side: side, photo: photo))
        renderer.scale = displayScale
        guard let image = renderer.cgImage else { return nil }
        return ShareImageEncoder.pngData(from: image)
    }

    private func loadSelectedPhoto() async {
        guard let photoId = viewModel.state.selectedPhotoId else {
            photo = nil
            return
        }
        // 카드 크기(최대 화면 폭 정도)를 넘는 원본은 줄여서 읽는다
        photo = await library.image(for: photoId, maxPixelSize: 1200 * displayScale)
    }

    // MARK: Route

    private func handle(_ route: SharePhotoViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .saved:
            viewModel.send(.routeHandled)
            toastCenter?.show(Strings.SharePhoto.savedToast)
            dismiss()
        case .permissionDeniedAlert, .errorAlert:
            // `.alert`가 route 를 읽어 보여주고, 닫을 때 비운다
            break
        }
    }

    private var alertMessage: String? {
        switch viewModel.route {
        case .permissionDeniedAlert(let message), .errorAlert(let message):
            return message
        case .saved, .none:
            return nil
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.send(.routeHandled) }
            }
        )
    }

    @ViewBuilder
    private var alertActions: some View {
        if case .permissionDeniedAlert = viewModel.route {
            Button(Strings.SharePhoto.alertCancel, role: .cancel) {}
            Button(Strings.SharePhoto.alertSettings) {
                if let url = URL(string: "app-settings:") {
                    openURL(url)
                }
            }
        } else {
            Button(Strings.commonOk, role: .cancel) {}
        }
    }
}

/// 카드 가운데 말풍선. 3초 뒤 0.3초 동안 사라진다 (처음 한 번만)
private struct ShareTooltip: View {
    let onDisappear: () -> Void

    @State private var opacity: Double = 1

    var body: some View {
        Text(Strings.sharePhotoTooltip)
            .font(.appleRegular(size: 14))
            .foregroundStyle(Color.gray5)
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 4, trailing: 10))
            .frame(height: 30)
            .background(Color.gray1, in: Capsule())
            .opacity(opacity)
            .allowsHitTesting(false)
            .task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 0
                } completion: {
                    onDisappear()
                }
            }
    }
}
