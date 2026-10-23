import SwiftUI

// 작성·수정 폼을 이루는 조각들. 레거시 `TextInputField`·`CategoryView`·`EmojiInputView`·`CustomHashtagField`·
// `WishStepsView`(편집)·`TargetAmountInputView`·`WishLinkInputView`·`WishPlaceView`(작성)·`WriteButton` 모양을 SwiftUI 로 옮겼다

/// 섹션 머리: 16pt 아이콘 + Regular 14 제목 (+ 회색 "(선택)")
struct WishFormHeader<Trailing: View>: View {
    let icon: Image
    let title: String
    var optional: String?
    var isFocused = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 4) {
            icon
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(isFocused ? Color.seepBlue : Color.gray5)
                .accessibilityHidden(true)
            (Text(verbatim: title).foregroundColor(isFocused ? .seepBlue : .gray5)
                + Text(verbatim: optional ?? "").foregroundColor(.gray4))
                .font(.appleRegular(size: 14))
            Spacer(minLength: 0)
            trailing()
        }
    }
}

extension WishFormHeader where Trailing == EmptyView {
    init(icon: Image, title: String, optional: String? = nil, isFocused: Bool = false) {
        self.init(icon: icon, title: title, optional: optional, isFocused: isFocused) { EmptyView() }
    }
}

/// 회색 입력 상자. 포커스면 흰 바탕 + seep-blue 테두리 (레거시 `TextInputField`)
struct WishFormFieldBox<Content: View>: View {
    var isFocused = false
    var minHeight: CGFloat = 52
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(isFocused ? Color.gray1 : Color.gray2, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.seepBlue, lineWidth: 1)
                }
            }
    }
}

/// 입력 칸 아래 빨간 안내 (Regular 12 option-red)
struct WishFormError: View {
    let message: String?

    var body: some View {
        if let message {
            Text(verbatim: message)
                .font(.appleRegular(size: 12))
                .foregroundStyle(Color.optionRed)
                .padding(.top, 8)
        }
    }
}

/// 이모지 원(72) + "R" 무작위 버튼 + 처음 한 번 뜨는 안내 말풍선 (레거시 `EmojiInputView`)
struct WishFormEmojiView: View {
    let emoji: String
    let isTooltipVisible: Bool
    let onTapEmoji: () -> Void
    let onTapRandom: () -> Void

    var body: some View {
        ZStack {
            Button(action: onTapEmoji) {
                ZStack {
                    if emoji.isEmpty {
                        Assets.Images.imgEmojiEmpty.swiftUIImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle().fill(Color.gray2)
                        Text(verbatim: emoji)
                            .font(.system(size: 36))
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Strings.WishForm.emojiAccessibility))
            .accessibilityValue(Text(verbatim: emoji))

            Button(action: onTapRandom) {
                Text(Strings.writeRandomButton)
                    .font(.appleBold(size: 12))
                    .foregroundStyle(Color.gray1)
                    .padding(.top, 2)
                    .frame(width: 20, height: 20)
                    .background(Color.seepBlue, in: RoundedRectangle(cornerRadius: 10))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Strings.WishForm.randomEmojiAccessibility))
            // 원 오른쪽 아래에 붙인다(원 오른쪽 4pt, 아래 끝 맞춤)
            .offset(x: 36 + 4 + 10, y: 36 - 10)

            if isTooltipVisible {
                Text(Strings.detailRandomInfo)
                    .font(.appleBold(size: 11))
                    .foregroundStyle(Color.gray1)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.gray5, in: RoundedRectangle(cornerRadius: 5))
                    .fixedSize()
                    .offset(x: 36 + 4 + 10 + 30, y: -12)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .sensoryFeedback(.impact(weight: .light), trigger: emoji)
    }
}

/// 카테고리 트랙(높이 48·라운드 24) 안 알약 (레거시 `CategoryView`)
struct WishFormCategoryTrack: View {
    let selected: Category
    let onSelect: (Category) -> Void

    private let categories: [Category] = [.wantToDo, .wantToGet, .wantToGo]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(categories) { category in
                Button {
                    onSelect(category)
                } label: {
                    Text(verbatim: category.title)
                        .font(category == selected ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                        .foregroundStyle(category == selected ? Color.gray1 : Color.gray4)
                        .padding(.horizontal, 18)
                        .frame(height: 30)
                        .background {
                            if category == selected {
                                Capsule()
                                    .fill(Color.seepBlue)
                                    .shadow(color: .black.opacity(0.15), radius: 1.5, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(category == selected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 48)
        // 디자인 시스템 category-track(#E8F6FF) — seep-blue 11% 와 같은 색
        .background(Color.categoryTrack, in: RoundedRectangle(cornerRadius: 24))
        .animation(.easeInOut(duration: 0.2), value: selected)
        .sensoryFeedback(.impact(weight: .light), trigger: selected)
    }
}

/// 알림 한 줄 (레거시 `WriteNotificationTableViewCell`). 꺼져 있으면 회색
struct WishFormNotificationRow: View {
    let notification: SeepNotification
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(Strings.WishForm.notificationRowFormat(
                    notification.type.toString,
                    notification.time.toString(format: "a h시 mm분")
                ))
                .font(.appleRegular(size: 16))
                .foregroundStyle(isEnabled ? Color.gray5 : Color.gray3)
                Spacer(minLength: 0)
                Assets.Icons.icArrowRight.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(isEnabled ? Color.gray5 : Color.gray3)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(isEnabled ? Color.gray1 : Color.gray2, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.gray2_5, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.3), value: isEnabled)
    }
}

/// 단계 편집 (GH-5 R-13, R-18). 추가·삭제만 하고 체크는 상세에서 한다
struct WishFormStepsEditor: View {
    let steps: [WishStep]
    let isAddEnabled: Bool
    let onTapAdd: () -> Void
    let onDelete: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WishFormHeader(icon: Image(systemName: "checklist"), title: Strings.Write.Step.title) {
                Button(action: onTapAdd) {
                    HStack(spacing: 2) {
                        Assets.Icons.icSmallPlus.swiftUIImage.renderingMode(.template)
                        Text(Strings.Detail.Step.add)
                            .font(.appleExtraBold(size: 14))
                    }
                    .foregroundStyle(isAddEnabled ? Color.seepBlue : Color.gray3)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 20)
            if !steps.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        if index > 0 {
                            Rectangle().fill(Color.gray2_5).frame(height: 1)
                        }
                        HStack {
                            Text(verbatim: step.title)
                                .font(.appleRegular(size: 16))
                                .foregroundStyle(Color.gray5)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Button {
                                onDelete(index)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.gray4)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(Strings.Detail.Step.delete))
                        }
                        .frame(height: 44)
                    }
                }
                .padding(.leading, 16)
                .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

/// 목표 금액 (GH-16 R-1, R-2). 갖고 싶어요에서만
struct WishFormTargetAmountField: View {
    let amount: Int
    let focus: FocusState<WishFormField?>.Binding
    let onChange: (String) -> Void

    var body: some View {
        let isFocused = focus.wrappedValue == .targetAmount
        VStack(alignment: .leading, spacing: 10) {
            WishFormHeader(
                icon: Image(systemName: "banknote"),
                title: Strings.Write.TargetAmount.title,
                optional: Strings.Write.TargetAmount.optional,
                isFocused: isFocused
            )
            WishFormFieldBox(isFocused: isFocused) {
                HStack(spacing: 4) {
                    TextField(
                        Strings.Write.TargetAmount.placeholder,
                        text: Binding(
                            get: { AmountFormatter.inputText(from: amount) },
                            set: onChange
                        )
                    )
                    .keyboardType(.numberPad)
                    .font(.appleRegular(size: 16))
                    .foregroundStyle(Color.gray5)
                    .focused(focus, equals: .targetAmount)
                    .accessibilityLabel(Text(Strings.Write.TargetAmount.title))
                    Text(Strings.Common.wonUnit)
                        .font(.appleRegular(size: 16))
                        .foregroundStyle(Color.gray5)
                }
            }
            Text(Strings.Write.TargetAmount.caption)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
        }
    }
}

/// 해시태그 칩 + 직접 입력 (레거시 해시태그 컬렉션뷰·`CustomHashtagField`)
struct WishFormHashtags: View {
    let selected: HashtagType?
    let custom: String
    let customError: String?
    let focus: FocusState<WishFormField?>.Binding
    let onSelect: (HashtagType) -> Void
    let onInputCustom: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WishFormFlowLayout(spacing: 8) {
                ForEach(HashtagType.array, id: \.self) { hashtag in
                    let isSelected = hashtag == selected
                    Button {
                        onSelect(hashtag)
                        focus.wrappedValue = nil
                    } label: {
                        Text(verbatim: hashtag.description)
                            .font(.appleExtraBold(size: 14))
                            .foregroundStyle(isSelected ? Color.gray1 : Color.gray4)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.seepBlue : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                if !isSelected {
                                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.gray3, lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            customField
            WishFormError(message: customError)
        }
    }

    private var customField: some View {
        let isFocused = focus.wrappedValue == .hashtag
        let isFilled = !custom.isEmpty && !isFocused
        return TextField(
            Strings.writePlaceholderHashtag,
            text: Binding(get: { custom }, set: onInputCustom)
        )
        .font(.appleExtraBold(size: 14))
        .foregroundStyle(isFilled ? Color.gray1 : Color.gray5)
        .submitLabel(.done)
        .focused(focus, equals: .hashtag)
        .fixedSize()
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isFilled ? Color.seepBlue : (isFocused ? Color.gray1 : Color.gray2), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 6).strokeBorder(Color.seepBlue, lineWidth: 1)
            }
        }
    }
}

/// 왼쪽 정렬로 줄바꿈하는 가로 배치 (레거시 `LeftAlignedCollectionViewFlowLayout`)
struct WishFormFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal: proposal, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            var row = rows[rows.count - 1]
            let nextWidth = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if nextWidth > maxWidth, !row.indices.isEmpty {
                let y = row.y + row.height + spacing
                rows.append(Row(indices: [index], y: y, width: size.width, height: size.height))
            } else {
                row.indices.append(index)
                row.width = nextWidth
                row.height = max(row.height, size.height)
                rows[rows.count - 1] = row
            }
        }
        return rows
    }
}

/// 작성·수정 완료 버튼 (레거시 `WriteButton`·`EditButton`). 필수값이 모자라도 눌러서 안내를 볼 수 있다
struct WishFormSaveButton: View {
    let state: WishFormSaveButtonState
    let isEditMode: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.appleExtraBold(size: 17))
                .foregroundStyle(Color.gray1)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        switch state {
        case .initial: return Strings.writeButtonOff
        case .more: return isEditMode ? Strings.detailButtonMore : Strings.writeButtonMore
        case .active: return isEditMode ? Strings.detailButtonOn : Strings.writeButtonOn
        }
    }

    private var background: Color {
        switch state {
        case .initial: return .ctaDisabled
        case .more: return .gray3
        case .active: return .tennisGreen
        }
    }
}
