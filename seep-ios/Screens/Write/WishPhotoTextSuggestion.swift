import SwiftUI

/// 사진 블록 아래 "사진에서 찾았어요" 캡션 + 제목·금액 칩 (GH-144 R-3).
/// 칩 모양은 GH-141 제안 칩과 같은 규칙(seep-blue 1.5pt 테두리·글자, 높이 36 알약, 줄바꿈)
struct WishPhotoTextSuggestion: View {
    let titles: [String]
    let amount: PhotoTextAmount?
    let onTapTitle: (String) -> Void
    let onTapAmount: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.WishDocument.PhotoText.caption)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
            WishFormFlowLayout(spacing: 8) {
                ForEach(titles, id: \.self) { title in
                    chip(text: title, icon: "textformat") { onTapTitle(title) }
                        .accessibilityHint(Text(Strings.WishDocument.PhotoText.titleHint))
                }
                if let amount {
                    chip(
                        text: Strings.WishDocument.PhotoText.amountFormat(AmountFormatter.money(amount.amount, currency: amount.currency)),
                        icon: Self.currencyIcon(amount.currency),
                        action: onTapAmount
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityHidden(true)
                Text(verbatim: text)
                    .font(.appleBold(size: 14))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.seepBlue)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .overlay(Capsule().strokeBorder(Color.seepBlue, lineWidth: 1.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// 금액 칩 아이콘: 원화는 wonsign.circle, 그 밖은 통화 기호 (디자인 메모)
    private static func currencyIcon(_ currency: String) -> String {
        switch currency {
        case AmountFormatter.krw: return "wonsign.circle"
        case "EUR": return "eurosign.circle"
        case "GBP": return "sterlingsign.circle"
        case "JPY", "CNY": return "yensign.circle"
        default: return "dollarsign.circle"
        }
    }
}
