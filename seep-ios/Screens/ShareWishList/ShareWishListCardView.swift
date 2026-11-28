import SwiftUI

/// 골라서 보내기 카드 (GH-125 R-3). 화면 미리보기와 공유 이미지가 같은 뷰를 쓴다
struct ShareWishListCardView: View {
    let card: ShareWishListCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 12)
            ForEach(card.rows) { row in
                divider
                ShareWishListCardRow(row: row)
            }
            if card.moreCount > 0 {
                divider
                Text(verbatim: Strings.ShareWishList.Card.moreFormat(card.moreCount))
                    .font(.appleSemiBold(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.leading, 42)
            }
            divider
            Text(verbatim: Strings.ShareWishList.Card.footer)
                .font(.appleBold(size: 11))
                .foregroundStyle(Color.gray3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 10)
        }
        .padding(EdgeInsets(top: 18, leading: 18, bottom: 14, trailing: 18))
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(verbatim: card.categoryTitle)
                    .foregroundStyle(Color.gray5)
                Text(verbatim: "\(card.count)")
                    .foregroundStyle(Color.seepBlue)
            }
            .font(.appleExtraBold(size: 18))
            .lineLimit(1)
            Spacer(minLength: 8)
            Text(verbatim: card.dateText)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray2_5)
            .frame(height: 1)
    }
}

/// 카드 한 줄: 이모지 · 제목(+도메인) · D-day 뱃지 (R-3)
private struct ShareWishListCardRow: View {
    let row: ShareWishListCard.Row

    var body: some View {
        HStack(spacing: 10) {
            Text(verbatim: row.emoji)
                .font(.system(size: 24))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: row.title)
                    .font(.appleSemiBold(size: 15))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(2)
                if let domain = row.domain {
                    Text(verbatim: domain)
                        .font(.appleMedium(size: 12))
                        .foregroundStyle(Color.gray4)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let dday = row.dday {
                DdayBadge(style: dday, farFutureText: Strings.homeInFarFurture, noDateText: Strings.homeNoDeanline)
                    .fixedSize()
            }
        }
        .padding(.vertical, 10)
    }
}

/// 카드를 공유용 PNG(@3x)로 그린다 (R-7). 화면 모드와 상관없이 라이트로, gray2 여백을 둘러 그린다
enum ShareWishListImageRenderer {
    static let padding: CGFloat = 20
    static let scale: CGFloat = 3

    @MainActor
    static func render(card: ShareWishListCard, cardWidth: CGFloat) -> Image? {
        guard cardWidth > 0 else { return nil }
        let renderer = ImageRenderer(content: ShareWishListCardView(card: card)
            .frame(width: cardWidth)
            .fixedSize(horizontal: false, vertical: true)
            .padding(padding)
            .background(Color.gray2)
            .environment(\.colorScheme, .light))
        renderer.scale = scale
        renderer.isOpaque = true
        guard let cgImage = renderer.cgImage else { return nil }
        return Image(decorative: cgImage, scale: scale)
    }
}
