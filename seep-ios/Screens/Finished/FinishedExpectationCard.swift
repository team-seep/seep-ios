import SwiftUI

/// "이뤄 보니 **n개**가 기대보다 좋았어요" + "모아 보기" · 카테고리별 better/기록 막대 3줄 · "기대랑 비교해 본 싶 m개 기준" (GH-139 R-6, R-7).
/// 막대는 gray2 트랙 + seep-blue 채움, 숫자 부분만 seep-blue Bold
struct FinishedExpectationCard: View {
    let summary: ExpectationSummary
    let isBetterFilterOn: Bool
    let onTapFilter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            VStack(spacing: 10) {
                ForEach(summary.rows) { row in
                    rowView(row)
                }
            }
            Text(Strings.Finished.Expectation.captionFormat(summary.recordedCount))
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Subviews

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            title
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button(action: onTapFilter) {
                Text(isBetterFilterOn ? Strings.Finished.Expectation.showAll : Strings.Finished.Expectation.more)
                    .font(.appleExtraBold(size: 14))
                    .foregroundStyle(Color.seepBlue)
                    .fixedSize()
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isBetterFilterOn ? .isSelected : [])
        }
    }

    /// 숫자 부분("n개")만 seep-blue Bold
    private var title: Text {
        let full = Strings.Finished.Expectation.titleFormat(summary.betterCount)
        let bold = Strings.Finished.Expectation.countFormat(summary.betterCount)
        guard let range = full.range(of: bold) else {
            return Text(verbatim: full).font(.appleSemiBold(size: 16)).foregroundStyle(Color.gray5)
        }
        return Text(verbatim: String(full[..<range.lowerBound])).font(.appleSemiBold(size: 16)).foregroundStyle(Color.gray5)
            + Text(verbatim: bold).font(.appleBold(size: 16)).foregroundStyle(Color.seepBlue)
            + Text(verbatim: String(full[range.upperBound...])).font(.appleSemiBold(size: 16)).foregroundStyle(Color.gray5)
    }

    private func rowView(_ row: ExpectationSummary.Row) -> some View {
        HStack(spacing: 12) {
            Text(verbatim: row.category.title)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
                .lineLimit(1)
                .frame(minWidth: 72, alignment: .leading)
                .fixedSize()
            bar(ratio: row.ratio)
            Text(verbatim: row.recordedCount == 0 ? Strings.Finished.Expectation.noRecord : "\(row.betterCount)/\(row.recordedCount)")
                .font(.appleMedium(size: 12))
                .foregroundStyle(row.recordedCount == 0 ? Color.gray4 : Color.gray5)
                .monospacedDigit()
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: row.recordedCount == 0
            ? row.category.title
            : Strings.Finished.Expectation.rowAccessibilityFormat(row.category.title, row.betterCount, row.recordedCount)))
        .accessibilityValue(row.recordedCount == 0 ? Text(Strings.Finished.Expectation.noRecord) : Text(verbatim: ""))
    }

    private func bar(ratio: Double) -> some View {
        Capsule()
            .fill(Color.gray2)
            .frame(height: 8)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.seepBlue)
                        .frame(width: proxy.size.width * ratio)
                }
            }
            .accessibilityHidden(true)
    }
}
