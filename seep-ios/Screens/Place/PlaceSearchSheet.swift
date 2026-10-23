import SwiftUI

/// "어디로 가고 싶어요?" 장소 검색 시트 (GH-31 R-3). 헤드라인 + 검색 필드(gray2·라운드 12·높이 52) + 후보 목록 + 안내.
/// 띄우는 쪽은 `.seepSheet(..., detent: .large)`로 띄우고 `onSelect`로 고른 장소를 받는다
struct PlaceSearchSheet: View {
    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let fieldHeight: CGFloat = 52
    }

    let onSelect: (WishPlace) -> Void

    @State private var viewModel: PlaceSearchSheetViewModel
    @State private var query = ""
    @FocusState private var isFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: PlaceSearchSheetViewModel = PlaceSearchSheetViewModel(),
        onSelect: @escaping (WishPlace) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(text: Strings.Detail.Place.Search.title, boldPart: Strings.Detail.Place.Search.titleBold)
                .padding(.top, 36)
            searchField
                .padding(.top, 24)
            results
                .padding(.top, 8)
            Text(Strings.Detail.Place.Search.caption)
                .font(.appleRegular(size: 13))
                .foregroundStyle(Color.gray4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, Layout.horizontalInset)
        .background(Color.gray1)
        .trackScreen(viewModel.screenName)
        .onAppear { isFieldFocused = true }
        .onChange(of: query) { _, newValue in
            viewModel.send(.inputQuery(newValue))
        }
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .foregroundStyle(Color.gray4)
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
            TextField(
                "",
                text: $query,
                prompt: Text(Strings.Detail.Place.Search.placeholder).foregroundStyle(Color.gray3)
            )
            .font(.appleRegular(size: 16))
            .foregroundStyle(Color.gray5)
            .submitLabel(.search)
            .focused($isFieldFocused)
            .onSubmit { isFieldFocused = false }
            .accessibilityLabel(Text(Strings.Detail.Place.Search.placeholder))
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.gray3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Strings.Detail.Place.Search.clear))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: Layout.fieldHeight)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }

    private var results: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.state.candidates.enumerated()), id: \.element.id) { index, candidate in
                    Button {
                        viewModel.send(.tapCandidate(index: index))
                    } label: {
                        PlaceSearchResultRow(candidate: candidate)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .overlay(alignment: .top) {
            if viewModel.state.isEmptyVisible {
                Text(Strings.Detail.Place.Search.empty)
                    .font(.appleMedium(size: 15))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Route
    private func handle(_ route: PlaceSearchSheetViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .selected(let place):
            isFieldFocused = false
            onSelect(place)
            dismiss()
        }
        viewModel.send(.routeHandled)
    }
}

/// 장소 검색 후보 한 줄: 핀 아이콘 · 이름 · 주소 · 아래 구분선 (GH-31 R-3)
struct PlaceSearchResultRow: View {
    let candidate: PlaceCandidate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 17))
                .foregroundStyle(Color.gray4)
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: candidate.title)
                    .font(.appleBold(size: 16))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
                if !candidate.subtitle.isEmpty {
                    Text(verbatim: candidate.subtitle)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray2_5)
                .frame(height: 1)
        }
    }
}
