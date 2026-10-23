import SwiftUI

/// 상세 "미래의 나에게" 섹션 (GH-61 R-2, R-6). 봉인된 편지는 본문을 그리지 않는다
struct DetailLetterSection: View {
    let viewModel: DetailLetterViewModel

    var body: some View {
        switch viewModel.state.letter {
        case .hidden:
            EmptyView()
        case .empty:
            DocumentSection(title: Strings.Detail.Letter.title) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Detail.Letter.empty)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                    TextActionButton(title: Strings.Detail.Letter.write) { viewModel.send(.tapWrite) }
                }
            }
        case .sealed(let caption):
            DocumentSection(
                title: Strings.Detail.Letter.title,
                actionTitle: Strings.Detail.Letter.rewrite,
                action: { viewModel.send(.tapRewrite) }
            ) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gray4)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Detail.Letter.sealedTitle)
                            .font(.appleSemiBold(size: 16))
                            .foregroundStyle(Color.gray5)
                        Text(verbatim: caption)
                            .font(.appleRegular(size: 13))
                            .foregroundStyle(Color.gray4)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }
        case .opened(let body, let writtenAt):
            DocumentSection(title: Strings.Detail.Letter.title) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: writtenAt)
                        .font(.appleRegular(size: 12))
                        .foregroundStyle(Color.gray4)
                    Text(verbatim: body)
                        .font(.appleRegular(size: 16))
                        .foregroundStyle(Color.gray5)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

/// "이루는 날의 나에게 / 편지를 남겨요" 시트 (GH-61 R-3)
struct FutureLetterSheet: View {
    @Bindable var viewModel: FutureLetterViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(text: Strings.FutureLetter.title, boldPart: Strings.FutureLetter.titleBold)
                .padding(.top, 24)

            VStack(alignment: .trailing, spacing: 8) {
                TextField(
                    "",
                    text: Binding(
                        get: { viewModel.state.letterText },
                        set: { viewModel.send(.inputLetter($0)) }
                    ),
                    prompt: Text(Strings.FutureLetter.placeholder).foregroundStyle(Color.gray3),
                    axis: .vertical
                )
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .lineLimit(5...8)
                .focused($isFocused)
                .accessibilityLabel(Text(Strings.FutureLetter.field))
                Text(verbatim: viewModel.state.countText)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
            }
            .padding(16)
            .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, 20)

            HStack(spacing: 6) {
                Image(systemName: "lock")
                    .font(.system(size: 13))
                Text(Strings.FutureLetter.notice)
                    .font(.appleRegular(size: 13))
            }
            .foregroundStyle(Color.gray4)
            .padding(.top, 12)

            SeepCTA(title: Strings.FutureLetter.seal, isEnabled: viewModel.state.isSealEnabled, fillsWidth: true) {
                viewModel.send(.tapSeal)
            }
            .padding(.top, 22)

            Button {
                viewModel.send(.tapLater)
            } label: {
                Text(Strings.FutureLetter.later)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear { isFocused = true }
        .onChange(of: viewModel.route) { _, route in
            if route == .dismiss { dismiss() }
        }
    }
}

/// 편지 섹션의 Route(시트·알럿)를 상세 화면에서 처리한다 (GH-61 R-3, R-4, R-7)
struct DetailLetterRouteHandler: ViewModifier {
    let letter: DetailLetterViewModel?
    let onError: (String) -> Void

    @State private var writingSheet: FutureLetterViewModel?
    @State private var isRewriteAlertPresented = false
    @State private var isDeleteAlertPresented = false

    func body(content: Content) -> some View {
        content
            .onChange(of: letter?.route) { _, route in handle(route) }
            .seepSheet(item: $writingSheet) { sheet in
                FutureLetterSheet(viewModel: sheet)
            }
            .alert(Text(Strings.Detail.Letter.RewriteAlert.title), isPresented: $isRewriteAlertPresented) {
                Button(role: .cancel) {} label: { Text(Strings.commonCancel) }
                Button { letter?.send(.confirmRewrite) } label: { Text(Strings.Detail.Letter.RewriteAlert.confirm) }
            } message: {
                Text(Strings.Detail.Letter.RewriteAlert.message)
            }
            .alert(Text(Strings.Detail.Letter.DeleteAlert.title), isPresented: $isDeleteAlertPresented) {
                Button(role: .cancel) {} label: { Text(Strings.commonCancel) }
                Button(role: .destructive) { letter?.send(.confirmDelete) } label: {
                    Text(Strings.Detail.Letter.DeleteAlert.confirm)
                }
            }
    }

    private func handle(_ route: DetailLetterViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .writeSheet(let sheet):
            writingSheet = sheet
        case .rewriteAlert:
            isRewriteAlertPresented = true
        case .deleteAlert:
            isDeleteAlertPresented = true
        case .errorAlert(let message):
            onError(message)
        }
        letter?.send(.routeHandled)
    }
}
