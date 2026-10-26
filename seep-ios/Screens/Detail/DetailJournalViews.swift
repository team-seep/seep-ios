import SwiftUI

/// 상세 "일지" 섹션 (GH-95 R-3, R-7): 헤더 "일지 {개수}" + "＋ 남기기"(홈에서 연 상세만) / 최신순 3줄 + "모두 보기 (n)"
struct DetailJournalSection: View {
    let journal: WishJournalViewModel

    var body: some View {
        let state = journal.state
        DocumentSection(
            title: Strings.Detail.Journal.title,
            count: state.journals.isEmpty ? nil : String(state.journals.count),
            actionTitle: state.isEditable ? Strings.Detail.Journal.add : nil,
            action: { journal.send(.tapAdd) }
        ) {
            if state.journals.isEmpty {
                Button {
                    journal.send(.tapAdd)
                } label: {
                    Text(Strings.Detail.Journal.addToday)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.seepBlue)
                        .frame(minHeight: 32, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(state.visibleJournals, id: \.id) { item in
                        row(item, isEditable: state.isEditable)
                    }
                    if state.isViewAllVisible {
                        Button {
                            journal.send(.tapViewAll)
                        } label: {
                            Text(Strings.Detail.Journal.viewAllFormat(state.journals.count))
                                .font(.appleMedium(size: 14))
                                .foregroundStyle(Color.seepBlue)
                                .frame(minHeight: 32, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func row(_ item: WishJournal, isEditable: Bool) -> some View {
        let content = HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(verbatim: DateUtils.toString(format: Strings.Detail.Journal.rowDateFormat, date: item.createdAt))
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
                .frame(width: 72, alignment: .leading)
            Text(verbatim: item.text)
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())

        if isEditable {
            content.contextMenu {
                Button(role: .destructive) {
                    journal.send(.tapDelete(journalId: item.id))
                } label: {
                    Text(Strings.Detail.Journal.delete)
                }
            }
        } else {
            content
        }
    }
}

/// "일지 한 줄 남기기" 시트 (GH-95 R-4): "오늘 {이모지} {제목}는 / 어땠나요?" · 날짜 · 한 줄 입력(최대 100자) · 남기기 CTA · 닫기
struct JournalInputSheet: View {
    @State var viewModel: JournalInputViewModel
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headline
                .padding(.top, 24)
            Text(verbatim: viewModel.dateText)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
                .padding(.top, 12)
            inputField
                .padding(.top, 16)
            HStack {
                Spacer()
                Text(verbatim: viewModel.state.countText)
                    .font(.appleRegular(size: 12))
                    .foregroundStyle(Color.gray4)
            }
            .padding(.top, 6)
            SeepCTA(
                title: Strings.Detail.Journal.Sheet.save,
                isEnabled: viewModel.state.isSaveEnabled,
                fillsWidth: true
            ) {
                viewModel.send(.tapSave)
            }
            .padding(.top, 20)
            Button {
                dismiss()
            } label: {
                Text(Strings.Detail.Journal.Sheet.close)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .trackScreen(viewModel.screenName)
        .onAppear { isFocused = true }
        .onChange(of: text) { _, newText in
            viewModel.send(.inputText(newText))
        }
        .onChange(of: viewModel.state.text) { _, limited in
            // 100자를 넘게 붙여넣으면 잘린 값으로 되돌린다 (TC-4)
            if limited != text { text = limited }
        }
        .onChange(of: viewModel.route) { _, route in
            if route == .dismiss { dismiss() }
        }
    }

    /// 제목은 한 줄 말줄임, 둘째 줄 "어땠나요?"는 굵게
    private var headline: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 0) {
                Text(verbatim: viewModel.titlePrefix)
                    .layoutPriority(1)
                Text(verbatim: viewModel.config.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(Strings.Detail.Journal.Sheet.titleSuffix)
                    .layoutPriority(1)
            }
            .font(.appleRegular(size: 22))
            Text(Strings.Detail.Journal.Sheet.titleBold)
                .font(.appleBold(size: 22))
        }
        .foregroundStyle(Color.gray5)
    }

    private var inputField: some View {
        TextField(Strings.Detail.Journal.Sheet.placeholder, text: $text)
            .font(.appleRegular(size: 16))
            .foregroundStyle(Color.gray5)
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit { viewModel.send(.tapSave) }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// 일지 섹션 Route: 입력 시트·토스트·오류 (GH-95). 상세 화면 본문이 길어 따로 둔다
struct DetailJournalEvents: ViewModifier {
    let journal: WishJournalViewModel?
    @Binding var errorMessage: String?
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    @State private var input: JournalInputViewModel?

    func body(content: Content) -> some View {
        content
            .onChange(of: journal?.route) { _, route in handle(route) }
            .seepSheet(item: $input) { inputViewModel in
                JournalInputSheet(viewModel: inputViewModel)
            }
    }

    private func handle(_ route: WishJournalViewModel.Route?) {
        guard let route, let journal else { return }
        switch route {
        case .journalInput(let inputViewModel):
            input = inputViewModel
        case .errorAlert(let message):
            errorMessage = message
        case .toast(let message):
            toastCenter?.show(message)
        }
        journal.send(.routeHandled)
    }
}
