import SwiftUI

/// 문서에 꺼낸 블록들, 놓는 순서대로 (GH-70 R-5)
struct WishDocumentBlocks: View {
    let viewModel: WishFormViewModel
    let focus: FocusState<WishFormField?>.Binding

    private var state: WishFormViewModel.State { viewModel.state }

    var body: some View {
        VStack(alignment: .leading, spacing: WishDocumentEditor.Layout.blockSpacing) {
            ForEach(viewModel.visibleBlocks, id: \.self) { block in
                blockView(block)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: WishDocumentBlock) -> some View {
        switch block {
        case .date:
            EmptyView()
        case .memo:
            memoBlock
        case .steps:
            stepsBlock
        case .notification:
            notificationBlock
        case .link:
            linkBlock
        case .targetAmount:
            targetAmountBlock
        case .place:
            placeBlock
        case .photo:
            photoBlock
        case .letter:
            letterBlock
        }
    }

    private func removeAction(_ block: WishDocumentBlock) -> () -> Void {
        {
            focus.wrappedValue = nil
            viewModel.send(.removeBlock(block))
        }
    }

    private var memoBlock: some View {
        DocumentSection(
            title: Strings.writeHeaderMemo,
            actionTitle: Strings.WishDocument.remove,
            action: removeAction(.memo)
        ) {
            TextField(
                "",
                text: Binding(get: { state.memo }, set: { viewModel.send(.inputMemo($0)) }),
                prompt: Text(Strings.WishDocument.memoPlaceholder).foregroundStyle(Color.gray3),
                axis: .vertical
            )
            .font(.appleRegular(size: 16))
            .lineSpacing(28 - 16 * 1.2)
            .foregroundStyle(Color.gray5)
            .tint(Color.seepBlue)
            .focused(focus, equals: .memo)
            .accessibilityLabel(Text(Strings.writeHeaderMemo))
            WishFormError(message: state.memoError)
        }
    }

    private var stepsBlock: some View {
        DocumentSection(
            title: Strings.Write.Step.title,
            actionTitle: Strings.WishDocument.remove,
            action: removeAction(.steps)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(state.steps.enumerated()), id: \.element.id) { index, step in
                    HStack(spacing: 10) {
                        Assets.Icons.icCheckOff.swiftUIImage
                            .resizable()
                            .foregroundStyle(Color.gray3)
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                        Text(verbatim: step.title)
                            .font(.appleRegular(size: 16))
                            .foregroundStyle(Color.gray5)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Button {
                            viewModel.send(.deleteStep(index: index))
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.gray4)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(Strings.Detail.Step.delete))
                    }
                    .frame(minHeight: 44)
                }
                TextActionButton(title: Strings.WishDocument.stepAdd) {
                    focus.wrappedValue = nil
                    viewModel.send(.tapAddStep)
                }
                .disabled(!state.isAddStepEnabled)
                .opacity(state.isAddStepEnabled ? 1 : 0.4)
            }
        }
    }

    private var notificationBlock: some View {
        DocumentSection(
            title: Strings.WishDocument.Section.notification,
            actionTitle: Strings.WishDocument.remove,
            action: removeAction(.notification)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(state.notifications.enumerated()), id: \.element.id) { index, notification in
                    Button {
                        focus.wrappedValue = nil
                        viewModel.send(.tapNotification(index: index))
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bell")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.gray4)
                                .accessibilityHidden(true)
                            Text(Strings.WishForm.notificationRowFormat(
                                notification.type.toString,
                                DisplayDate.time(notification.time)
                            ))
                            .font(.appleRegular(size: 16))
                            .foregroundStyle(Color.gray5)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.gray3)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                TextActionButton(title: "＋ " + Strings.writeAddNotification) {
                    focus.wrappedValue = nil
                    viewModel.send(.tapAddNotification)
                }
            }
        }
    }

    private var linkBlock: some View {
        DocumentSection(
            title: Strings.Write.Link.title,
            actionTitle: Strings.WishDocument.remove,
            action: removeAction(.link)
        ) {
            HStack(spacing: 8) {
                TextField(
                    "",
                    text: Binding(get: { state.linkText }, set: { viewModel.send(.inputLink($0)) }),
                    prompt: Text(Strings.WishDocument.linkPlaceholder).foregroundStyle(Color.gray3)
                )
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .tint(Color.seepBlue)
                .focused(focus, equals: .link)
                .accessibilityLabel(Text(Strings.Write.Link.title))
                // 앱이 en 로컬라이즈만 있어 라벨은 영어로 그려진다. 한글 화면에 섞이지 않게 아이콘만 쓴다
                PasteButton(payloadType: String.self) { strings in
                    guard let pasted = strings.first else { return }
                    Task { @MainActor in viewModel.send(.pasteLink(pasted)) }
                }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.capsule)
                .tint(Color.seepBlue)
            }
            .frame(minHeight: 44)
            if let error = state.linkError {
                WishFormError(message: error)
            }
            WishFormLinkPreviewCard(preview: state.linkPreview)
        }
    }

    private var targetAmountBlock: some View {
        DocumentSection(
            title: Strings.Write.TargetAmount.title,
            actionTitle: Strings.WishDocument.remove,
            action: removeAction(.targetAmount)
        ) {
            HStack(spacing: 4) {
                TextField(
                    "",
                    text: Binding(
                        get: { AmountFormatter.inputText(from: state.targetAmount) },
                        set: { viewModel.send(.inputTargetAmount($0)) }
                    ),
                    prompt: Text(Strings.Write.TargetAmount.placeholder).foregroundStyle(Color.gray3)
                )
                .keyboardType(.numberPad)
                .font(.appleExtraBold(size: 22))
                .foregroundStyle(Color.gray5)
                .tint(Color.seepBlue)
                .focused(focus, equals: .targetAmount)
                .fixedSize()
                .accessibilityLabel(Text(Strings.Write.TargetAmount.title))
                Text(Strings.Common.wonUnit)
                    .font(.appleRegular(size: 16))
                    .foregroundStyle(Color.gray4)
            }
            .frame(minHeight: 44)
            Text(Strings.Write.TargetAmount.caption)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
        }
    }

    @ViewBuilder
    private var placeBlock: some View {
        if let place = state.place {
            DocumentSection(
                title: Strings.Detail.Place.title,
                actionTitle: Strings.WishDocument.remove,
                action: removeAction(.place)
            ) {
                Button {
                    focus.wrappedValue = nil
                    viewModel.send(.tapPlace)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.gray4)
                            .padding(.top, 2)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: place.name)
                                .font(.appleBold(size: 16))
                                .foregroundStyle(Color.gray5)
                            if !place.address.isEmpty {
                                Text(verbatim: place.address)
                                    .font(.appleRegular(size: 14))
                                    .foregroundStyle(Color.gray4)
                            }
                        }
                        .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 사진을 누르면 다시 고른다 (GH-61 R-10)
    @ViewBuilder
    private var photoBlock: some View {
        if let image = photoImage {
            DocumentSection(
                title: Strings.Detail.Photo.title,
                actionTitle: Strings.WishDocument.remove,
                action: removeAction(.photo)
            ) {
                Button {
                    focus.wrappedValue = nil
                    viewModel.send(.tapPhoto)
                } label: {
                    PhotoFrame(image: image)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(Strings.Detail.Photo.change))
            }
        }
    }

    private var photoImage: CGImage? {
        switch viewModel.photoPreview {
        case .file(let url): return DetailImageDecoder.cgImage(url: url)
        case .data(let data): return DetailImageDecoder.cgImage(data: data, maxPixelSize: 1600)
        case nil: return nil
        }
    }

    /// 봉인 카드. 누르면 다시 쓸지 묻는다 (GH-61 R-4, R-10)
    @ViewBuilder
    private var letterBlock: some View {
        if let caption = viewModel.letterCaption {
            DocumentSection(
                title: Strings.Detail.Letter.title,
                actionTitle: Strings.WishDocument.remove,
                action: removeAction(.letter)
            ) {
                Button {
                    focus.wrappedValue = nil
                    viewModel.send(.tapLetter)
                } label: {
                    SealedLetterCard(caption: caption)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 하단 더하기 칩 줄. 키보드가 올라오면 키보드 위에 붙는다 (GH-70 R-6)
struct WishDocumentChipBar: View {
    let viewModel: WishFormViewModel
    let focus: FocusState<WishFormField?>.Binding

    var body: some View {
        let chips = viewModel.chips
        if !chips.isEmpty || focus.wrappedValue != nil {
            HStack(spacing: 0) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(chips, id: \.self) { block in
                            Button {
                                viewModel.send(.tapChip(block))
                            } label: {
                                Label {
                                    Text(verbatim: block.chipTitle)
                                } icon: {
                                    Image(systemName: block.chipIcon)
                                }
                                .font(.appleMedium(size: 14))
                                .foregroundStyle(Color.gray5)
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .seepGlassCapsule()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                if focus.wrappedValue != nil {
                    Button {
                        focus.wrappedValue = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.gray5)
                            .frame(width: 38, height: 38)
                            .seepGlassCapsule()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(Strings.WishForm.keyboardDone))
                    .padding(.trailing, 16)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: chips)
        }
    }
}

extension WishDocumentBlock {
    var chipTitle: String {
        switch self {
        case .date: return Strings.WishDocument.Chip.date
        case .memo: return Strings.WishDocument.Chip.memo
        case .steps: return Strings.WishDocument.Chip.steps
        case .notification: return Strings.WishDocument.Chip.notification
        case .link: return Strings.WishDocument.Chip.link
        case .targetAmount: return Strings.WishDocument.Chip.targetAmount
        case .place: return Strings.WishDocument.Chip.place
        case .photo: return Strings.WishDocument.Chip.photo
        case .letter: return Strings.WishDocument.Chip.letter
        }
    }

    var chipIcon: String {
        switch self {
        case .date: return "calendar"
        case .memo: return "text.alignleft"
        case .steps: return "checklist"
        case .notification: return "bell"
        case .link: return "link"
        case .targetAmount: return "wonsign"
        case .place: return "mappin.and.ellipse"
        case .photo: return "photo"
        case .letter: return "envelope"
        }
    }
}

extension View {
    /// iOS 26 이상은 리퀴드 글래스, 그 아래는 반투명 재질 캡슐
    @ViewBuilder
    func seepGlassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Capsule())
        } else {
            background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.gray2_5, lineWidth: 0.5))
        }
    }
}
