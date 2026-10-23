import SwiftUI

/// 상세 문서 머리: 이모지 → 제목(`doc-title` Bold 26/36, 최대 2줄) → D-day 줄 → 메타 줄 (GH-59 R-2~R-4).
/// 보기 전용이라 파란 글자·화살표·입력 테두리가 없고 탭 반응도 없다 (R-7)
struct DocumentTitleBlock: View {
    let summary: WishDetailSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !summary.emoji.isEmpty {
                Text(verbatim: summary.emoji)
                    .font(.system(size: 44))
                    .frame(height: 52)
                    .padding(.bottom, 12)
                    .accessibilityHidden(true)
            }
            Text(verbatim: summary.title)
                .font(.appleBold(size: 26))
                .lineSpacing(36 - 26 * 1.2)
                .foregroundStyle(Color.gray5)
                .lineLimit(2)
                .truncationMode(.tail)
                .accessibilityAddTraits(.isHeader)
            DocumentDdayLine(line: summary.ddayLine)
                .padding(.top, 6)
            DocumentMetaLine(summary: summary)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 제목 바로 아래 큰 D-day 줄 (GH-59 R-3). 숫자 ExtraBold 30/36(단어는 Bold 20/28) + 날짜 Medium 14 `gray4`, 기준선 맞춤
struct DocumentDdayLine: View {
    let line: WishDetailSummary.DdayLine

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(verbatim: line.text)
                .font(line.isWord ? .appleBold(size: 20) : .appleExtraBold(size: 30))
                .foregroundStyle(line.tone.color)
                .frame(minHeight: line.isWord ? 28 : 36)
                .fixedSize()
            if let dateText = line.dateText {
                Text(verbatim: dateText)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: [line.text, line.dateText].compactMap { $0 }.joined(separator: ", ")))
    }
}

/// D-day 줄 아래 메타 한 줄: 카테고리 · 🔔 알림 요약 · #해시태그 (GH-59 R-4). `gray4`, 탭 반응 없음
struct DocumentMetaLine: View {
    let summary: WishDetailSummary

    var body: some View {
        summary.metaItems.enumerated().reduce(Text(verbatim: "")) { text, element in
            let (index, item) = element
            let separator = index > 0 ? Text(verbatim: "  ·  ").foregroundStyle(Color.gray3) : Text(verbatim: "")
            return text + separator + itemText(item)
        }
        .font(.appleRegular(size: 14))
        .foregroundStyle(Color.gray4)
        .lineSpacing(22 - 14 * 1.2)
        .accessibilityLabel(Text(verbatim: summary.metaText))
    }

    private func itemText(_ item: WishDetailSummary.MetaItem) -> Text {
        switch item {
        case .category(let value), .hashtag(let value):
            return Text(verbatim: value)
        case .notification(let value):
            return Text(Image(systemName: "bell")).font(.system(size: 12)) + Text(verbatim: " " + value)
        }
    }
}

/// 메모 본문 (GH-59 R-5). `doc-body` Regular 16/28, 선택·복사만 되고 편집은 안 된다
struct DocumentBody: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.appleRegular(size: 16))
            .lineSpacing(28 - 16 * 1.2)
            .foregroundStyle(Color.gray5)
            .textSelection(.enabled)
            .tint(Color.gray4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 상세 상단 바 (GH-59 R-8): 시스템 내비게이션 바에 [축소 제목 + 작은 D-day] · "수정" · ⋯ 를 얹는다. 뒤로 버튼은 시스템 것을 쓴다.
/// 스크롤해 큰 제목이 지나가면 가운데에 제목(말줄임)과 D-day(ExtraBold 13, 색만, 잘리지 않음)를 보인다
struct DetailToolbar: ToolbarContent {
    let title: String
    let dday: WishDetailSummary.DdayLine?
    let isTitleCollapsed: Bool
    let isEditVisible: Bool
    let onEdit: () -> Void
    let onMore: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Text(verbatim: title)
                    .font(.appleSemiBold(size: 16))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let dday {
                    Text(verbatim: dday.text)
                        .font(.appleExtraBold(size: 13))
                        .foregroundStyle(dday.tone.color)
                        .fixedSize()
                }
            }
            .opacity(isTitleCollapsed ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isTitleCollapsed)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHidden(!isTitleCollapsed)
        }
        if isEditVisible {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onEdit) {
                    Text(Strings.Detail.Nav.edit)
                        .font(.appleExtraBold(size: 14))
                        .foregroundStyle(Color.seepBlue)
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onMore) {
                Assets.Icons.icMore.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray5)
            }
            .accessibilityLabel(Text(Strings.Detail.Nav.more))
        }
    }
}
