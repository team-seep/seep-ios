import SwiftUI

/// "이어지는 싶" 한 줄 (GH-84 R-4)
struct DetailChainRow: Equatable, Identifiable {
    let id: String
    let emoji: String
    let title: String
    /// 이룬 싶 "{날짜} 이뤘어요"(소감이 있으면 · "소감"), 지금 싶 "지금 이 싶", 그 밖은 nil
    let caption: String?
    let isCurrent: Bool
    let isFinished: Bool

    /// 앞 → 지금 → 다음 순서
    static func rows(chain: WishChain) -> [DetailChainRow] {
        chain.previous.map { row($0, isCurrent: false) }
            + [row(chain.current, isCurrent: true)]
            + chain.next.map { row($0, isCurrent: false) }
    }

    private static func row(_ wish: Wish, isCurrent: Bool) -> DetailChainRow {
        DetailChainRow(
            id: wish.id,
            emoji: wish.emoji,
            title: wish.title,
            caption: isCurrent ? Strings.Detail.Chain.current : finishedCaption(wish),
            isCurrent: isCurrent,
            isFinished: wish.isSuccess
        )
    }

    private static func finishedCaption(_ wish: Wish) -> String? {
        guard wish.isSuccess else { return nil }
        let date = wish.finishDate.map { DateUtils.toString(format: "yyyy. M. d.", date: $0) } ?? ""
        let note = wish.finishNote.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty
            ? Strings.Detail.Chain.finishedFormat(date)
            : Strings.Detail.Chain.finishedNoteFormat(date, note)
    }
}

/// 상세 "이어지는 싶" 섹션: 체크 원 24 + 세로 연결선(`gray2-5` 2pt). 지금 싶 줄은 누를 수 없다 (GH-84 R-4, R-5, R-7)
struct DetailChainSection: View {
    let chain: WishChain
    let onTapWish: (String) -> Void

    private var rows: [DetailChainRow] { DetailChainRow.rows(chain: chain) }

    var body: some View {
        DocumentSection(
            title: Strings.Detail.Chain.title,
            count: Strings.Detail.Chain.positionFormat(chain.position)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                if chain.hiddenPreviousCount > 0 {
                    Text(Strings.Detail.Chain.hiddenFormat(chain.hiddenPreviousCount))
                        .font(.appleMedium(size: 13))
                        .foregroundStyle(Color.gray4)
                        .padding(.leading, 36)
                        .frame(minHeight: 28, alignment: .leading)
                    connector
                }
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { connector }
                    rowView(row)
                }
            }
        }
    }

    private var connector: some View {
        Rectangle()
            .fill(Color.gray2_5)
            .frame(width: 2, height: 14)
            .padding(.leading, 11)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func rowView(_ row: DetailChainRow) -> some View {
        if row.isCurrent {
            rowContent(row)
        } else {
            Button {
                onTapWish(row.id)
            } label: {
                rowContent(row)
            }
            .buttonStyle(.plain)
        }
    }

    private func rowContent(_ row: DetailChainRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            checkCircle(isOn: row.isFinished)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(verbatim: row.emoji)
                        .font(.system(size: 16))
                    Text(verbatim: row.title)
                        .font(row.isCurrent ? .appleBold(size: 16) : .appleRegular(size: 16))
                        .foregroundStyle(row.isFinished ? Color.gray4 : Color.gray5)
                        .strikethrough(row.isFinished, color: Color.gray4)
                        .lineLimit(1)
                }
                if let caption = row.caption {
                    Text(verbatim: caption)
                        .font(.appleRegular(size: 13))
                        .foregroundStyle(Color.gray4)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if !row.isCurrent {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.gray3)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func checkCircle(isOn: Bool) -> some View {
        ZStack {
            if isOn {
                Circle().fill(Color.tennisGreen)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.onAccent)
            } else {
                Circle().strokeBorder(Color.gray3, lineWidth: 1.5)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}
