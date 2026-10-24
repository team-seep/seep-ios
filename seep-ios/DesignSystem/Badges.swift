import SwiftUI

/// D-day 뱃지. Bold 11, 안쪽 위 3·좌우 6·아래 1, 라운드 4 (디자인 시스템 DdayBadge)
struct DdayBadge: View {
    let style: DdayBadgeStyle
    let farFutureText: String
    let noDateText: String

    var body: some View {
        Text(verbatim: style.text(farFuture: farFutureText, noDate: noDateText))
            .font(.appleBold(size: 11))
            .foregroundStyle(style.textColor)
            .padding(EdgeInsets(top: 3, leading: 6, bottom: 1, trailing: 6))
            .background(style.backgroundColor, in: RoundedRectangle(cornerRadius: 4))
    }
}

/// 해시태그 뱃지 (디자인 시스템 TagBadge)
struct TagBadge: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.appleBold(size: 11))
            .foregroundStyle(Color.tagText)
            .padding(EdgeInsets(top: 3, leading: 6, bottom: 1, trailing: 6))
            .background(Color.tagBg, in: RoundedRectangle(cornerRadius: 4))
    }
}

/// 체크 원. 켜짐 = tennis-green 원 + 흰 체크, 꺼짐 = gray3 2pt 테두리 (디자인 시스템 `ic_check_on`/`ic_check_off`)
struct CheckCircle: View {
    let isChecked: Bool
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            if isChecked {
                Circle()
                    .fill(Color.tennisGreen)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .heavy))
                    .foregroundStyle(Color.onAccent)
            } else {
                Circle()
                    .strokeBorder(Color.gray3, lineWidth: 2)
            }
        }
        .frame(width: size, height: size)
    }
}
