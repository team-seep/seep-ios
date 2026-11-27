import SwiftUI

/// 갖고 싶어요 탭 맨 위 "다 합치면" 카드 (GH-148 R-1 ~ R-7).
/// 라벨 · 남은 금액(큰 줄) · 진행 막대 · 모은 돈/목표 · 다른 통화 보조 줄 · 빠진 싶 안내. 누르면 포함된 싶이 펼쳐진다
struct HomeWishTotalCardView: View {
    let summary: WishTotalSummary
    let isExpanded: Bool
    let onToggle: () -> Void
    let onTapItem: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                summaryContent
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(Strings.Home.WishTotal.accessibilityHint))

            if isExpanded {
                expandedContent
                    .padding(.top, 10)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(verbatim: title)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 2) {
                    Text(isExpanded ? Strings.Home.WishTotal.collapse : Strings.Home.WishTotal.expand)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
            }

            highlighted(
                Strings.Home.WishTotal.remainingFormat(money(summary.primary.remainingAmount, summary.primary.currency)),
                amount: money(summary.primary.remainingAmount, summary.primary.currency),
                size: 22
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            progressBar(ratio: summary.primary.ratio)

            HStack(alignment: .top, spacing: 8) {
                Text(verbatim: Strings.Home.WishTotal.savedFormat(money(summary.primary.savedAmount, summary.primary.currency)))
                Spacer(minLength: 0)
                Text(verbatim: Strings.Home.WishTotal.targetFormat(
                    money(summary.primary.targetAmount, summary.primary.currency),
                    Strings.Home.WishTotal.countFormat(summary.primary.count)
                ))
                .multilineTextAlignment(.trailing)
            }
            .font(.appleMedium(size: 12))
            .foregroundStyle(Color.gray4)

            ForEach(summary.secondaryGroups, id: \.currency) { group in
                secondaryLine(group)
            }

            if summary.excludedCount > 0 {
                Text(verbatim: Strings.Home.WishTotal.excludedFormat(summary.excludedCount))
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.gray2_5)
                .frame(height: 1)

            VStack(spacing: 0) {
                ForEach(summary.groups, id: \.currency) { group in
                    ForEach(group.items) { item in
                        itemRow(item)
                    }
                }
            }

            Text(Strings.Home.WishTotal.footer)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
        }
    }

    private func itemRow(_ item: WishTotalSummary.Item) -> some View {
        Button {
            onTapItem(item.id)
        } label: {
            HStack(spacing: 10) {
                Text(verbatim: item.emoji)
                    .font(.system(size: 20))
                Text(verbatim: item.title)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if item.isCompleted {
                    Text(Strings.Home.WishTotal.completed)
                        .font(.appleBold(size: 14))
                        .foregroundStyle(Color.tennisGreen)
                } else {
                    Text(verbatim: money(item.remainingAmount, item.currency))
                        .font(.appleBold(size: 14))
                        .foregroundStyle(Color.gray5)
                }
            }
            .frame(minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func secondaryLine(_ group: WishTotalSummary.CurrencyGroup) -> some View {
        let amount = money(group.remainingAmount, group.currency)
        let count = Strings.Home.WishTotal.countFormat(group.count)
        var attributed = AttributedString(Strings.Home.WishTotal.secondaryFormat(amount, count))
        attributed.font = .appleBold(size: 16)
        attributed.foregroundColor = .gray5
        if let range = attributed.range(of: amount) {
            attributed[range].foregroundColor = .seepBlue
        }
        if let range = attributed.range(of: count, options: .backwards) {
            attributed[range].font = .appleMedium(size: 12)
            attributed[range].foregroundColor = .gray4
        }
        return Text(attributed).lineLimit(1)
    }

    private func progressBar(ratio: Double) -> some View {
        Capsule()
            .fill(Color.gray2)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.tennisGreen)
                        .frame(width: proxy.size.width * ratio)
                }
            }
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }

    private var title: String {
        guard let tag = summary.tag else { return Strings.Home.WishTotal.title }
        return Strings.Home.WishTotal.tagTitleFormat(HashtagType.displayName(for: tag))
    }

    /// 문장 안 금액 부분만 seep-blue
    private func highlighted(_ text: String, amount: String, size: CGFloat) -> Text {
        var attributed = AttributedString(text)
        attributed.font = .appleBold(size: size)
        attributed.foregroundColor = .gray5
        if let range = attributed.range(of: amount) {
            attributed[range].foregroundColor = .seepBlue
        }
        return Text(attributed)
    }

    private func money(_ amount: Int, _ currency: String) -> String {
        AmountFormatter.money(amount, currency: currency)
    }
}
