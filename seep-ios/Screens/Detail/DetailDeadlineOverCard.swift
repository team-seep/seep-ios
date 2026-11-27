import SwiftUI

/// 기간 기한이 지난 싶의 "아직 하고 싶어요?" 카드 (GH-118 R-6). `gray2` 바탕·라운드 16,
/// 제목 Bold 15 · 설명 Regular 14 `gray4` · [미루기(tennis-green) | 기한 없애기(흰 바탕)]
struct DetailDeadlineOverCard: View {
    let card: WishDetailViewModel.DeadlineOverCard
    let onPostpone: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Deadline.OverCard.title)
                .font(.appleBold(size: 15))
                .foregroundStyle(Color.gray5)
            Text(Strings.Deadline.OverCard.message)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            HStack(spacing: 8) {
                Button(action: onPostpone) {
                    Text(verbatim: card.postponeTitle)
                        .font(.appleBold(size: 14))
                        .foregroundStyle(Color.onAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.tennisGreen, in: Capsule())
                }
                .buttonStyle(.plain)
                Button(action: onClear) {
                    Text(Strings.Deadline.OverCard.remove)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.gray1, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 16))
    }
}
