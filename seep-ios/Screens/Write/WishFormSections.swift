import SwiftUI

// 작성·수정 문서(GH-70)가 쓰는 조각: 입력 안내, 해시태그 시트 내용

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

/// 태그 시트 내용: 기본 태그 칩(여러 개) + 직접 입력 태그 칩·입력 칸 + 전에 쓴 태그 (GH-136 R-2)
struct WishFormHashtags: View {
    let selection: WishTagSelection
    let customInput: String
    let error: String?
    let suggestedTags: [String]
    let focus: FocusState<WishFormField?>.Binding
    let onToggle: (HashtagType) -> Void
    let onInputCustom: (String) -> Void
    let onSubmitCustom: () -> Void
    let onRemove: (String) -> Void
    let onSelectRecent: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WishFormFlowLayout(spacing: 8) {
                ForEach(HashtagType.array, id: \.self) { hashtag in
                    let isSelected = selection.contains(hashtag)
                    Button {
                        onToggle(hashtag)
                    } label: {
                        TagChipLabel(text: hashtag.description, isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            WishFormFlowLayout(spacing: 8) {
                ForEach(selection.customTags, id: \.self) { tag in
                    Button {
                        onRemove(tag)
                    } label: {
                        HStack(spacing: 4) {
                            Text(verbatim: tag)
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(.appleExtraBold(size: 14))
                        .foregroundStyle(Color.onAccent)
                        .padding(.leading, 8)
                        .padding(.trailing, 6)
                        .padding(.vertical, 6)
                        .background(Color.seepBlue, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(Strings.WishDocument.HashtagSheet.removeFormat(tag)))
                }
                if !selection.isFull {
                    customField
                }
            }
            .padding(.top, 4)
            WishFormError(message: error)
            if !suggestedTags.isEmpty {
                recentTags
            }
        }
    }

    private var customField: some View {
        let isFocused = focus.wrappedValue == .hashtag
        return TextField(
            Strings.writePlaceholderHashtag,
            text: Binding(get: { customInput }, set: onInputCustom)
        )
        .font(.appleExtraBold(size: 14))
        .foregroundStyle(Color.gray5)
        .submitLabel(.done)
        .onSubmit(onSubmitCustom)
        .focused(focus, equals: .hashtag)
        .fixedSize()
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isFocused ? Color.gray1 : Color.gray2, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 6).strokeBorder(Color.seepBlue, lineWidth: 1)
            }
        }
    }

    private var recentTags: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.WishDocument.HashtagSheet.recent)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
            WishFormFlowLayout(spacing: 8) {
                ForEach(suggestedTags, id: \.self) { tag in
                    Button {
                        onSelectRecent(tag)
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text(verbatim: tag)
                        }
                        .font(.appleExtraBold(size: 14))
                        .foregroundStyle(Color.gray4)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6).strokeBorder(Color.gray3, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 12)
    }
}

/// 기본 태그 칩. 고르면 seep-blue 바탕 + 흰 글자, 아니면 gray3 테두리 + gray4 글자
private struct TagChipLabel: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(verbatim: text)
            .font(.appleExtraBold(size: 14))
            .foregroundStyle(isSelected ? Color.onAccent : Color.gray4)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.seepBlue : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.gray3, lineWidth: 1)
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

