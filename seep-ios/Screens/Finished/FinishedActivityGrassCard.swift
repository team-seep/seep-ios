import SwiftUI

/// "싶에 다가간 날" 카드: 제목 · "올해 n일" · 월 라벨 · 7×주 칸 · "적게 ··· 많이" 범례 (GH-146 R-1, R-3, R-8, R-9).
/// 칸 크기는 그대로 두고 카드 너비에 들어가는 만큼 최근 주를 보여 준다(18~26주)
struct FinishedActivityGrassCard: View {
    let grass: ActivityGrass
    let onTapDay: (Date) -> Void

    @State private var contentWidth: CGFloat = 0

    private let calendar = Calendar.current
    private let cellSize = CGFloat(ActivityGrass.cellSize)
    private let cellSpacing = CGFloat(ActivityGrass.cellSpacing)

    private var weekCount: Int {
        ActivityGrass.visibleWeekCount(contentWidth: Double(contentWidth))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            VStack(alignment: .leading, spacing: 6) {
                monthLabels
                grid
            }
            legend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
        .padding(14)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Subviews

    private var header: some View {
        HStack {
            Text(Strings.Finished.ActivityGrass.title)
                .font(.appleSemiBold(size: 16))
                .foregroundStyle(Color.gray5)
            Spacer(minLength: 8)
            yearCount
        }
        .accessibilityElement(children: .combine)
        // 카드 전체 요약 (R-8)
        .accessibilityValue(Text(verbatim: grass.summaryAccessibilityLabel(weekCount: weekCount)))
        .accessibilityAddTraits(.isHeader)
    }

    /// "올해 **n일**" — 숫자 부분만 굵게
    private var yearCount: Text {
        let full = Strings.Finished.ActivityGrass.yearFormat(grass.yearDayCount)
        let bold = Strings.Finished.ActivityGrass.dayCountFormat(grass.yearDayCount)
        guard let range = full.range(of: bold) else {
            return Text(verbatim: full).font(.appleMedium(size: 12)).foregroundStyle(Color.gray4)
        }
        return Text(verbatim: String(full[..<range.lowerBound])).font(.appleMedium(size: 12)).foregroundStyle(Color.gray4)
            + Text(verbatim: bold).font(.appleBold(size: 12)).foregroundStyle(Color.gray5)
            + Text(verbatim: String(full[range.upperBound...])).font(.appleMedium(size: 12)).foregroundStyle(Color.gray4)
    }

    private var monthLabels: some View {
        ZStack(alignment: .topLeading) {
            ForEach(grass.monthLabels(inLast: weekCount, calendar: calendar)) { label in
                Text(verbatim: DisplayDate.string(label.monthStart, template: "MMM", calendar: calendar))
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
                    .fixedSize()
                    .offset(x: CGFloat(label.column) * (cellSize + cellSpacing))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 14, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private var grid: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(grass.visibleWeeks(weekCount), id: \.first?.date) { week in
                VStack(spacing: cellSpacing) {
                    ForEach(week) { cell in
                        cellView(cell)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: ActivityGrassCell) -> some View {
        if cell.isFuture {
            Color.clear
                .frame(width: cellSize, height: cellSize)
                .accessibilityHidden(true)
        } else {
            Button {
                onTapDay(cell.date)
            } label: {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Self.color(level: cell.level))
                    .frame(width: cellSize, height: cellSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: ActivityGrass.accessibilityLabel(for: cell, calendar: calendar)))
        }
    }

    private var legend: some View {
        HStack(spacing: 3) {
            Spacer(minLength: 0)
            Text(Strings.Finished.ActivityGrass.legendLess)
                .padding(.trailing, 1)
            ForEach(0...4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Self.color(level: level))
                    .frame(width: 10, height: 10)
            }
            Text(Strings.Finished.ActivityGrass.legendMore)
                .padding(.leading, 1)
        }
        .font(.appleMedium(size: 12))
        .foregroundStyle(Color.gray4)
        .accessibilityHidden(true)
    }

    // MARK: Helpers

    /// 0 = gray2, 1~4 = tennis-green 불투명도 0.25 / 0.5 / 0.75 / 1 (R-3)
    static func color(level: Int) -> Color {
        level == 0 ? Color.gray2 : Color.tennisGreen.opacity(Double(level) * 0.25)
    }
}
