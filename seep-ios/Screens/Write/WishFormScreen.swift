import SwiftUI

/// 작성·수정 폼을 여는 방식 (GH-64 P2)
enum WishFormMode: Identifiable, Equatable {
    case add(Category)
    case edit(Wish)

    var id: String {
        switch self {
        case .add(let category): return "add-" + category.rawValue
        case .edit(let wish): return "edit-" + wish.id
        }
    }

    static func == (lhs: WishFormMode, rhs: WishFormMode) -> Bool {
        lhs.id == rhs.id
    }
}

/// 폼에서 키보드로 입력하는 칸
enum WishFormField: Hashable {
    case title
    case targetAmount
    case link
    case memo
    case hashtag
}

/// 위시 작성·수정 화면 (TC-401~409, 501~504).
/// `onFinish`는 저장한 위시(닫기면 nil)를 넘기고, 화면 닫기는 띄운 쪽이 한다
struct WishFormScreen: View {
    /// 닫기·뒤로 버튼 터치 영역. 아이콘(24pt)은 그대로 두고 44pt 로 넓힌다 (GH-10 TC7)
    static let topButtonSize: CGFloat = 44

    let mode: WishFormMode
    let onFinish: (Wish?) -> Void

    @State private var viewModel: WishFormViewModel
    @FocusState private var focus: WishFormField?
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    @State private var isAddStepAlertPresented = false
    @State private var newStepTitle = ""

    init(mode: WishFormMode, onFinish: @escaping (Wish?) -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        _viewModel = State(initialValue: WishFormViewModel(config: .init(mode: mode)))
    }

    /// 테스트·프리뷰에서 ViewModel 을 넣는다
    init(mode: WishFormMode, viewModel: WishFormViewModel, onFinish: @escaping (Wish?) -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        _viewModel = State(initialValue: viewModel)
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var state: WishFormViewModel.State { viewModel.state }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !isEditMode {
                        HeadlineText(text: Strings.writeTitle, boldPart: Strings.wrtieTitleBold)
                            .padding(.top, 23)
                            .padding(.horizontal, 20)
                    }
                    WishFormEmojiView(
                        emoji: state.emoji,
                        isTooltipVisible: state.isTooltipVisible,
                        onTapEmoji: {
                            focus = nil
                            viewModel.send(.tapEmoji)
                        },
                        onTapRandom: { viewModel.send(.tapRandomEmoji) }
                    )
                    .padding(.top, 16)
                    WishFormCategoryTrack(selected: state.category) { category in
                        viewModel.send(.selectCategory(category))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 0) {
                        titleField
                            .padding(.top, 31)
                        if state.isLinkVisible {
                            WishFormLinkField(
                                text: state.linkText,
                                error: state.linkError,
                                preview: state.linkPreview,
                                focus: $focus,
                                onChange: { viewModel.send(.inputLink($0)) },
                                onPaste: { viewModel.send(.pasteLink($0)) }
                            )
                            .padding(.top, 24)
                        }
                        dateField
                            .padding(.top, 24)
                        if viewModel.isPlaceVisible {
                            WishFormPlaceField(
                                place: state.place,
                                emoji: state.emoji,
                                onTapPlace: {
                                    focus = nil
                                    viewModel.send(.tapPlace)
                                },
                                onDelete: { viewModel.send(.deletePlace) }
                            )
                            .padding(.top, 26)
                        }
                        if state.isTargetAmountVisible {
                            WishFormTargetAmountField(amount: state.targetAmount, focus: $focus) {
                                viewModel.send(.inputTargetAmount($0))
                            }
                            .padding(.top, 26)
                        }
                        WishFormStepsEditor(
                            steps: state.steps,
                            isAddEnabled: state.isAddStepEnabled,
                            onTapAdd: { viewModel.send(.tapAddStep) },
                            onDelete: { viewModel.send(.deleteStep(index: $0)) }
                        )
                        .padding(.top, 26)
                        notificationSection
                            .padding(.top, 16)
                        memoField
                            .padding(.top, 26)
                        WishFormHeader(icon: Assets.Icons.icHashtag.swiftUIImage, title: Strings.writeHeaderHashtag)
                            .padding(.top, 26)
                        WishFormHashtags(
                            selected: state.selectedHashtag,
                            custom: state.customHashtag,
                            customError: state.customHashtagError,
                            focus: $focus,
                            onSelect: { viewModel.send(.selectHashtag($0)) },
                            onInputCustom: { viewModel.send(.inputCustomHashtag($0)) }
                        )
                        .padding(.top, 10)
                        WishFormSaveButton(state: state.saveButtonState, isEditMode: isEditMode) {
                            focus = nil
                            viewModel.send(.tapSave)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
                // 넓은 화면(듀오 안쪽)은 600pt 기둥 가운데 (레거시 WideScreenContainerView)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { focus = nil }
        }
        .background(Color.gray1)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    focus = nil
                } label: {
                    Text(Strings.WishForm.keyboardDone)
                        .foregroundStyle(Color.seepBlue)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.category)
        .animation(.easeInOut(duration: 0.3), value: state.isTooltipVisible)
        .onAppear { viewModel.send(.onAppear) }
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
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
    }

    // MARK: 상단

    private var topBar: some View {
        HStack {
            if isEditMode {
                Button {
                    viewModel.send(.tapClose)
                } label: {
                    Assets.Icons.icChevronBack.swiftUIImage
                        .frame(width: Self.topButtonSize, height: Self.topButtonSize)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Strings.WishForm.back))
                Spacer()
            } else {
                Spacer()
                Button {
                    viewModel.send(.tapClose)
                } label: {
                    Assets.Icons.icClose.swiftUIImage
                        .frame(width: Self.topButtonSize, height: Self.topButtonSize)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Strings.WishForm.close))
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 3)
    }

    // MARK: 칸

    private var titleField: some View {
        let isFocused = focus == .title
        return VStack(alignment: .leading, spacing: 10) {
            WishFormHeader(icon: Assets.Icons.icTitle.swiftUIImage, title: Strings.writeHeaderTitle, isFocused: isFocused)
            WishFormFieldBox(isFocused: isFocused) {
                TextField(state.titlePlaceholder, text: Binding(
                    get: { state.title },
                    set: { viewModel.send(.inputTitle($0)) }
                ))
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .focused($focus, equals: .title)
                .submitLabel(.done)
            }
            WishFormError(message: state.titleError)
                .padding(.top, -10)
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 10) {
            WishFormHeader(icon: Assets.Icons.icCalendar.swiftUIImage, title: Strings.writeHeaderDate) {
                Toggle(isOn: Binding(
                    get: { state.isDeadlineEnabled },
                    set: { viewModel.send(.toggleDeadline($0)) }
                )) {
                    Text(Strings.writeDateSwitchTitle)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray5)
                }
                .tint(Color.tennisGreen)
                .scaleEffect(0.75, anchor: .trailing)
                .fixedSize()
            }
            .frame(height: 20)
            Button {
                focus = nil
                viewModel.send(.tapDate)
            } label: {
                WishFormFieldBox(isFocused: state.sheet == .date) {
                    Text(verbatim: dateText)
                        .font(.appleRegular(size: 16))
                        .foregroundStyle(dateTextColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(!state.isDeadlineEnabled)
            WishFormError(message: state.deadlineError)
                .padding(.top, -10)
        }
    }

    private var dateText: String {
        guard state.isDeadlineEnabled else { return Strings.writePlaceholderDateDisable }
        guard let deadline = state.deadline else { return Strings.writePlaceholderDateEnable }
        return DateUtils.toString(format: Strings.WishForm.dateFormat, date: deadline)
    }

    private var dateTextColor: Color {
        guard state.isDeadlineEnabled else { return .gray5 }
        return state.deadline == nil ? .gray3 : .gray5
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            WishFormHeader(icon: Assets.Icons.icNotificationNormal.swiftUIImage, title: Strings.writeHeaderNotification) {
                Toggle(isOn: Binding(
                    get: { state.isNotificationEnabled },
                    set: { viewModel.send(.toggleNotification($0)) }
                )) {
                    Text(Strings.writeNotificationSwitchTitle)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray5)
                }
                .tint(Color.tennisGreen)
                .scaleEffect(0.75, anchor: .trailing)
                .fixedSize()
            }
            .frame(height: 20)
            VStack(spacing: 8) {
                ForEach(Array(state.notifications.enumerated()), id: \.element.id) { index, notification in
                    WishFormNotificationRow(notification: notification, isEnabled: state.isNotificationEnabled) {
                        focus = nil
                        viewModel.send(.tapNotification(index: index))
                    }
                }
            }
            .padding(.top, 10)
            Button {
                focus = nil
                viewModel.send(.tapAddNotification)
            } label: {
                HStack(spacing: 2) {
                    Assets.Icons.icSmallPlus.swiftUIImage.renderingMode(.template)
                    Text(Strings.writeAddNotification)
                        .font(.appleExtraBold(size: 14))
                }
                .foregroundStyle(state.isNotificationEnabled ? Color.seepBlue : Color.gray3)
                .frame(maxWidth: .infinity, minHeight: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!state.isNotificationEnabled)
            .padding(.top, 8)
        }
    }

    private var memoField: some View {
        let isFocused = focus == .memo
        return VStack(alignment: .leading, spacing: 10) {
            WishFormHeader(icon: Assets.Icons.icMemo.swiftUIImage, title: Strings.writeHeaderMemo, isFocused: isFocused)
            WishFormFieldBox(isFocused: isFocused, minHeight: 82) {
                TextField(
                    Strings.wrtiePlaceholderMemo,
                    text: Binding(get: { state.memo }, set: { viewModel.send(.inputMemo($0)) }),
                    axis: .vertical
                )
                .lineLimit(3...)
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .focused($focus, equals: .memo)
                .padding(.vertical, 16)
            }
            WishFormError(message: state.memoError)
                .padding(.top, -10)
        }
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
            VStack(spacing: 16) {
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        case .notification(let config):
            NotificationEditorSheet(
                config: config,
                onSave: { viewModel.send(.saveNotification($0, index: $1)) },
                onDelete: { viewModel.send(.deleteNotification(index: $0)) }
            )
        case .placeSearch:
            PlaceSearchSheet(onSelect: { viewModel.send(.selectPlace($0)) })
        }
    }

    // MARK: Route

    private func handle(_ route: WishFormViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .toast(let message):
            toastCenter?.show(message)
        case .addStepAlert:
            newStepTitle = ""
            isAddStepAlertPresented = true
        case .finish(let wish):
            onFinish(wish)
        }
        viewModel.send(.routeHandled)
    }
}
