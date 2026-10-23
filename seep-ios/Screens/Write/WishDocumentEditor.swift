import SwiftUI

/// 작성·수정 문서 (GH-70 W1 "문서에 바로 쓰기").
/// 상세와 같은 흰 문서에 이모지·제목만 두고, 나머지 칸은 하단 더하기 칩으로 꺼낸다.
/// 작성은 `WishFormScreen` 안에서, 수정은 상세가 제자리에서 이 뷰로 바꾼다 (R-14)
struct WishDocumentEditor: View {
    enum Layout {
        static let horizontalInset: CGFloat = 24
        static let blockSpacing: CGFloat = 40
    }

    let viewModel: WishFormViewModel
    let onFinish: (Wish?) -> Void

    @FocusState private var focus: WishFormField?
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    @State private var isAddStepAlertPresented = false
    @State private var newStepTitle = ""
    @State private var isDiscardDialogPresented = false

    private var state: WishFormViewModel.State { viewModel.state }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                head
                if !viewModel.visibleBlocks.isEmpty {
                    WishDocumentBlocks(viewModel: viewModel, focus: $focus)
                        .padding(.top, Layout.blockSpacing)
                }
            }
            .padding(.horizontal, Layout.horizontalInset)
            .padding(.top, 8)
            .padding(.bottom, 40)
            // 넓은 화면(듀오 안쪽)은 600pt 기둥 가운데 (GH-12)
            .frame(maxWidth: SeepLayout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.gray1)
        // 키보드가 올라오면 칩 줄이 키보드 바로 위에 붙는다 (R-6)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WishDocumentChipBar(viewModel: viewModel, focus: $focus)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .animation(.easeInOut(duration: 0.2), value: viewModel.visibleBlocks)
        .animation(.easeInOut(duration: 0.3), value: state.isTooltipVisible)
        .onAppear {
            viewModel.send(.onAppear)
            // 작성은 제목에 바로 커서 (R-11). 전체 화면이 다 올라온 뒤에 준다
            if !viewModel.isEditing {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(450))
                    focus = .title
                }
            }
        }
        .task(id: state.isTooltipVisible) {
            guard state.isTooltipVisible else { return }
            try? await Task.sleep(for: .seconds(3))
            viewModel.send(.hideTooltip)
        }
        .trackScreen(viewModel.screenName)
        .seepSheet(item: sheetBinding, detent: .mediumLarge) { sheet in
            sheetContent(sheet)
        }
        .alert(Strings.Detail.Step.AddAlert.title, isPresented: $isAddStepAlertPresented) {
            TextField(Strings.Detail.Step.AddAlert.placeholder, text: $newStepTitle)
            Button(Strings.commonCancel, role: .cancel) { newStepTitle = "" }
            Button(Strings.Detail.Step.AddAlert.confirm) {
                viewModel.send(.addStep(newStepTitle))
                newStepTitle = ""
            }
        }
        .confirmationDialog(
            viewModel.isEditing ? Strings.WishDocument.Discard.editTitle : Strings.WishDocument.Discard.addTitle,
            isPresented: $isDiscardDialogPresented,
            titleVisibility: .visible
        ) {
            Button(Strings.WishDocument.Discard.confirm, role: .destructive) {
                viewModel.send(.confirmDiscard)
            }
            Button(Strings.WishDocument.Discard.keep, role: .cancel) {}
        }
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
    }

    // MARK: 상단 바 (R-10, R-14)

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                focus = nil
                viewModel.send(.tapClose)
            } label: {
                if viewModel.isEditing {
                    Text(Strings.WishDocument.cancel)
                        .foregroundStyle(Color.gray5)
                } else {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.gray5)
                }
            }
            .accessibilityLabel(Text(viewModel.isEditing ? Strings.WishDocument.cancel : Strings.WishForm.close))
        }
        ToolbarItem(placement: .confirmationAction) {
            // 제목이 비어 있어도 눌러서 안내를 볼 수 있게 끄지 않고 흐리게만 그린다 (R-10)
            Button {
                focus = nil
                viewModel.send(.tapSave)
            } label: {
                Text(viewModel.isEditing ? Strings.WishDocument.done : Strings.WishDocument.save)
            }
            .tint(state.saveButtonState == .active ? Color.seepBlue : Color.gray3)
        }
    }

    // MARK: 머리 (R-2 ~ R-4)

    private var head: some View {
        VStack(alignment: .leading, spacing: 0) {
            emojiView
                .padding(.bottom, 12)
            TextField(
                "",
                text: titleBinding,
                prompt: Text(verbatim: state.titlePlaceholder).foregroundStyle(Color.gray3),
                axis: .vertical
            )
            .font(.appleBold(size: 26))
            .foregroundStyle(Color.gray5)
            .tint(Color.seepBlue)
            .lineLimit(1...2)
            .submitLabel(.done)
            .focused($focus, equals: .title)
            .accessibilityLabel(Text(Strings.writeHeaderTitle))
            if let error = state.titleError {
                WishFormError(message: error)
            }
            if state.isDeadlineEnabled, let deadline = state.deadline {
                Button {
                    focus = nil
                    viewModel.send(.tapDate)
                } label: {
                    DocumentDdayLine(line: WishDetailSummary.ddayLine(endDate: deadline))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            metaLine
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 제목 입력. 줄바꿈은 받지 않고 키보드를 내린다 (줄바꿈 키 = 완료)
    private var titleBinding: Binding<String> {
        Binding(
            get: { state.title },
            set: { text in
                if text.contains("\n") {
                    focus = nil
                    viewModel.send(.inputTitle(text.replacingOccurrences(of: "\n", with: "")))
                } else {
                    viewModel.send(.inputTitle(text))
                }
            }
        )
    }

    private var emojiView: some View {
        HStack(alignment: .center, spacing: 10) {
            Group {
                if state.emoji.isEmpty {
                    Assets.Images.imgEmojiEmpty.swiftUIImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                } else {
                    Text(verbatim: state.emoji)
                        .font(.system(size: 44))
                        .frame(height: 52)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focus = nil
                viewModel.send(.tapEmoji)
            }
            // 길게 누르면 무작위 (R-3)
            .onLongPressGesture(minimumDuration: 0.4) {
                viewModel.send(.tapRandomEmoji)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(Strings.WishForm.emojiAccessibility))
            .accessibilityValue(Text(verbatim: state.emoji))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { viewModel.send(.tapEmoji) }
            .accessibilityAction(named: Text(Strings.WishForm.randomEmojiAccessibility)) {
                viewModel.send(.tapRandomEmoji)
            }

            if state.isTooltipVisible {
                Text(Strings.WishDocument.randomTooltip)
                    .font(.appleBold(size: 11))
                    .foregroundStyle(Color.gray1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.gray5, in: RoundedRectangle(cornerRadius: 5))
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: state.emoji)
    }

    /// 카테고리 ▾ · #태그 (R-4)
    private var metaLine: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach([Category.wantToDo, .wantToGet, .wantToGo]) { category in
                    Button {
                        viewModel.send(.selectCategory(category))
                    } label: {
                        if category == state.category {
                            Label(category.title, systemImage: "checkmark")
                        } else {
                            Text(verbatim: category.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(verbatim: state.category.title)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Color.gray4)
                .frame(minHeight: 32)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(Text(Strings.WishDocument.categoryMenu))
            .accessibilityValue(Text(verbatim: state.category.title))
            Text(verbatim: "·")
                .foregroundStyle(Color.gray3)
            Button {
                focus = nil
                viewModel.send(.tapHashtag)
            } label: {
                Text(verbatim: hashtagText ?? Strings.WishDocument.hashtagEmpty)
                    .foregroundStyle(hashtagText == nil ? Color.gray3 : Color.gray4)
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .font(.appleRegular(size: 14))
        .sensoryFeedback(.impact(weight: .light), trigger: state.category)
    }

    private var hashtagText: String? {
        if !state.customHashtag.isEmpty { return "#" + state.customHashtag }
        guard let hashtag = state.selectedHashtag else { return nil }
        return "#" + hashtag.description
    }

    // MARK: 시트

    private var sheetBinding: Binding<WishFormSheet?> {
        Binding(
            get: { viewModel.state.sheet },
            set: { sheet in
                if sheet == nil { viewModel.send(.dismissSheet) }
            }
        )
    }

    @ViewBuilder
    private func sheetContent(_ sheet: WishFormSheet) -> some View {
        switch sheet {
        case .emoji:
            EmojiPickerSheet(recentStore: EmojiRecentStore()) { emoji in
                viewModel.send(.selectEmoji(emoji))
            }
        case .date:
            VStack(spacing: 12) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.state.deadline ?? Date() },
                        set: { viewModel.send(.inputDeadline($0)) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))
                SeepCTA(title: Strings.WishForm.dateConfirm, fillsWidth: true) {
                    viewModel.send(.dismissSheet)
                }
                // 날짜를 없애면 알림도 같이 꺼진다 (R-7)
                TextActionButton(title: Strings.WishDocument.dateRemove) {
                    viewModel.send(.removeBlock(.date))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
        case .notification(let config):
            NotificationEditorSheet(
                config: config,
                onSave: { viewModel.send(.saveNotification($0, index: $1)) },
                onDelete: { viewModel.send(.deleteNotification(index: $0)) }
            )
        case .placeSearch:
            PlaceSearchSheet(onSelect: { viewModel.send(.selectPlace($0)) })
        case .hashtag:
            WishHashtagSheet(
                selected: state.selectedHashtag,
                custom: state.customHashtag,
                customError: state.customHashtagError,
                onSelect: {
                    viewModel.send(.selectHashtag($0))
                    viewModel.send(.dismissSheet)
                },
                onInputCustom: { viewModel.send(.inputCustomHashtag($0)) },
                onDone: { viewModel.send(.dismissSheet) }
            )
        }
    }

    // MARK: Route

    private func handle(_ route: WishFormViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .toast(let message):
            toastCenter?.show(message)
        case .addStepAlert:
            focus = nil
            newStepTitle = ""
            isAddStepAlertPresented = true
        case .finish(let wish):
            onFinish(wish)
        case .focus(let field):
            // 칸이 문서에 들어간 다음 커서를 준다
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                focus = field
            }
        case .confirmDiscard:
            isDiscardDialogPresented = true
        }
        viewModel.send(.routeHandled)
    }
}

/// 해시태그 시트: 추천 태그 + 직접 입력 (GH-70 R-4)
private struct WishHashtagSheet: View {
    let selected: HashtagType?
    let custom: String
    let customError: String?
    let onSelect: (HashtagType) -> Void
    let onInputCustom: (String) -> Void
    let onDone: () -> Void

    @FocusState private var focus: WishFormField?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Strings.WishDocument.HashtagSheet.title)
                .font(.appleBold(size: 18))
                .foregroundStyle(Color.gray5)
            WishFormHashtags(
                selected: selected,
                custom: custom,
                customError: customError,
                focus: $focus,
                onSelect: onSelect,
                onInputCustom: onInputCustom
            )
            .onSubmit(onDone)
            Spacer(minLength: 0)
            SeepCTA(title: Strings.WishForm.dateConfirm, fillsWidth: true, action: onDone)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 16)
    }
}
