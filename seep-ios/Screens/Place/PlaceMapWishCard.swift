import SwiftUI

/// 지도에서 핀을 고르면 아래에 뜨는 위시 카드: 이모지 · 제목 · D-day · 장소 이름 (GH-31 R-7).
/// 흰 바탕·라운드 16·그림자, 높이 88
struct PlaceMapWishCard: View {
    static let height: CGFloat = 88

    let wish: Wish
    let onTap: () -> Void

    private var ddayStyle: DdayBadgeStyle { DdayBadgeStyle(endDate: wish.endDate) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(verbatim: wish.emoji)
                    .font(.system(size: 36))
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: wish.title)
                        .font(.appleBold(size: 16))
                        .foregroundStyle(Color.gray5)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        DdayBadge(
                            style: ddayStyle,
                            farFutureText: Strings.homeInFarFurture,
                            noDateText: Strings.homeNoDeanline
                        )
                        .fixedSize()
                        if let placeName = wish.place?.name {
                            Text(verbatim: placeName)
                                .font(.appleRegular(size: 14))
                                .foregroundStyle(Color.gray4)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.gray4)
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 16)
            .frame(height: Self.height)
            .background(Color.gray1, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.gray5.opacity(0.12), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityText))
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        let dday = ddayStyle.text(farFuture: Strings.homeInFarFurture, noDate: Strings.homeNoDeanline)
        return [wish.title, dday, wish.place?.name].compactMap { $0 }.joined(separator: ", ")
    }
}
