import SwiftUI

/// 상세 "미래의 나에게" 섹션 (GH-61 R-6, R-9). 봉인된 편지는 본문을 그리지 않는다
struct DetailLetterSection: View {
    let letter: DetailLetter

    var body: some View {
        switch letter {
        case .hidden:
            EmptyView()
        case .sealed(let caption):
            DocumentSection(title: Strings.Detail.Letter.title) {
                SealedLetterCard(caption: caption)
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

/// 자물쇠 + "이루는 날 열려요" + 봉인일·글자 수 (상세 섹션·문서 블록)
struct SealedLetterCard: View {
    let caption: String

    var body: some View {
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
