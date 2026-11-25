import SwiftUI

/// 잔디 칸을 눌러 여는 그날 시트 (GH-146 R-5).
/// "{날짜},\n싶에 **n번 다가갔어요**" + 행동 줄(시간순). 행동이 없으면 날짜와 "쉬어 간 날이에요"만
struct FinishedActivityDaySheet: View {
    let day: ActivityDay
    let onTapActivity: (WishActivity) -> Void

    /// 이보다 줄이 많으면 목록을 스크롤로 둔다 (시트가 화면을 넘지 않게)
    private static let maxRowsWithoutScroll = 6
    private static let rowHeight: CGFloat = 60
    private static let rowSpacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headline
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)

            if day.activities.isEmpty {
                Text(Strings.Finished.ActivityDay.restDay)
                    .font(.appleMedium(size: 16))
                    .foregroundStyle(Color.gray4)
                    .padding(.top, 12)
            } else {
                rows
                    .padding(.top, 18)
            }

            Text(Strings.Finished.ActivityDay.footnote)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: Subviews

    @ViewBuilder
    private var headline: some View {
        let date = DisplayDate.monthDayWeekday(day.date)
        if day.activities.isEmpty {
            HeadlineText(text: date, boldPart: "")
        } else {
            let count = day.activities.count
            HeadlineText(
                text: Strings.Finished.ActivityDay.dateFormat(date) + "\n" + Strings.Finished.ActivityDay.countFormat(count),
                boldPart: Strings.Finished.ActivityDay.countBoldFormat(count)
            )
        }
    }

    @ViewBuilder
    private var rows: some View {
        let list = VStack(spacing: Self.rowSpacing) {
            ForEach(day.activities) { activity in
                row(activity)
            }
        }
        if day.activities.count > Self.maxRowsWithoutScroll {
            ScrollView {
                list
            }
            .frame(height: (Self.rowHeight + Self.rowSpacing) * (CGFloat(Self.maxRowsWithoutScroll) + 0.5))
        } else {
            list
        }
    }

    private func row(_ activity: WishActivity) -> some View {
        Button {
            onTapActivity(activity)
        } label: {
            HStack(spacing: 12) {
                Text(verbatim: activity.emoji)
                    .font(.system(size: 24))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: activity.wishTitle)
                        .font(.appleSemiBold(size: 16))
                        .foregroundStyle(Color.gray5)
                        .lineLimit(1)
                    Text(verbatim: activity.subtitle)
                        .font(.appleMedium(size: 12))
                        .foregroundStyle(Color.gray4)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.gray3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(height: Self.rowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

extension WishActivity {
    /// 줄 보조 문구: "이뤘어요!" / "모은 돈 +{금액}" / "단계 체크 · {단계}" / "일지 한 줄" / "담았어요" (R-5)
    var subtitle: String {
        switch kind {
        case .added:
            return Strings.Finished.ActivityDay.added
        case .stepDone(let stepTitle):
            return Strings.Finished.ActivityDay.stepFormat(stepTitle)
        case .saving(let amount, let currency):
            return Strings.Finished.ActivityDay.savingFormat(AmountFormatter.money(amount, currency: currency))
        case .journal:
            return Strings.Finished.ActivityDay.journal
        case .finished:
            return Strings.Finished.ActivityDay.finished
        }
    }
}
