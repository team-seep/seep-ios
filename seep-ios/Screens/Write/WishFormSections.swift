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

