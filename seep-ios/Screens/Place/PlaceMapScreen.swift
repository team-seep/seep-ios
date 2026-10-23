import SwiftUI
import MapKit

/// "가고 싶은 곳 지도" (GH-31 R-6~R-9, GH-64 TC-38·TC-1001~1002). 위치 권한을 쓰지 않는다 — 현재 위치 표시 없음.
/// 싶 탭(가고 싶어요)에서 `.placeMap`으로 쌓는다
struct PlaceMapScreen: View {
    private enum Layout {
        static let headerHeight: CGFloat = 50
        static let horizontalInset: CGFloat = 20
    }

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PlaceMapScreenViewModel()
    @State private var position: MapCameraPosition = .automatic
    /// 이미 맞춘 영역 요청. 같은 요청으로 다시 옮기지 않는다
    @State private var appliedFitId: Int?

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                map
                overlays
            }
        }
        .background(Color.gray1)
        .onAppear { viewModel.send(.onAppear) }
        .trackScreen(viewModel.screenName)
        .onChange(of: viewModel.state.cameraFit, initial: true) { _, fit in
            guard let fit, fit.id != appliedFitId else { return }
            appliedFitId = fit.id
            fitAllPins()
        }
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
    }

    private var header: some View {
        ZStack {
            Text(Strings.PlaceMap.title)
                .font(.appleBold(size: 17))
                .foregroundStyle(Color.gray5)
            HStack {
                Button {
                    dismiss()
                } label: {
                    Assets.Icons.icChevronBack.swiftUIImage
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Strings.PlaceMap.back))
                Spacer()
            }
            .padding(.leading, 10)
        }
        .frame(height: Layout.headerHeight)
    }

    private var map: some View {
        Map(position: $position, selection: selectionBinding) {
            ForEach(viewModel.state.wishes, id: \.id) { wish in
                if let coordinate = wish.placeCoordinate {
                    Annotation(wish.title, coordinate: coordinate, anchor: .bottom) {
                        EmojiPin(emoji: wish.emoji, isSelected: wish.id == viewModel.state.selectedWishId)
                            .zIndex(wish.id == viewModel.state.selectedWishId ? 1 : 0)
                    }
                    .annotationTitles(.hidden)
                    .tag(wish.id)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }

    private var overlays: some View {
        VStack(spacing: 0) {
            HStack {
                if viewModel.state.count > 0 {
                    countBadge
                }
                Spacer()
            }
            .padding(.top, 16)
            Spacer()
            if let wish = viewModel.state.selectedWish {
                PlaceMapWishCard(wish: wish) {
                    viewModel.send(.tapCard)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, Layout.horizontalInset)
        .overlay {
            if viewModel.state.isEmpty {
                Text(Strings.PlaceMap.empty)
                    .font(.appleMedium(size: 15))
                    .foregroundStyle(Color.gray5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, Layout.horizontalInset)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.selectedWishId)
    }

    /// "장소를 붙인 곳 n곳" — 숫자만 Bold seep-blue
    private var countBadge: some View {
        countText
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.gray1, in: Capsule())
            .accessibilityLabel(Text(verbatim: Strings.PlaceMap.countFormat(viewModel.state.count)))
    }

    private var countText: Text {
        let count = viewModel.state.count
        let text = Strings.PlaceMap.countFormat(count)
        let normal: (String) -> Text = { Text(verbatim: $0).font(.appleMedium(size: 14)).foregroundStyle(Color.gray5) }
        guard let range = text.range(of: "\(count)", options: .backwards) else { return normal(text) }
        return normal(String(text[..<range.lowerBound]))
            + Text(verbatim: "\(count)").font(.appleBold(size: 14)).foregroundStyle(Color.seepBlue)
            + normal(String(text[range.upperBound...]))
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: { viewModel.state.selectedWishId },
            set: { viewModel.send(.selectPin(wishId: $0)) }
        )
    }

    private func fitAllPins() {
        let coordinates = viewModel.state.wishes.compactMap(\.placeCoordinate)
        guard let region = PlaceMapCamera.region(for: coordinates) else { return }
        position = .region(region)
    }

    // MARK: Route
    private func handle(_ route: PlaceMapScreenViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .wishDetail(let id):
            router.push(.wishDetail(id: id, isFinished: false))
        }
        viewModel.send(.routeHandled)
    }
}
