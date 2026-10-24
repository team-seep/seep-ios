import SwiftUI
import WidgetKit

/// 중형 가로 카드: 이모지 26 · 제목 SemiBold 13 두 줄 · 아래 D-day (GH-87 R-1)
struct WishHorizontalItemView: View {
    let wish: Wish
    /// 위젯 실제 폭에서 계산한 아이템 폭. 기기별 표로 정하면 표에 없는 기기(듀오 등)에서 어긋난다.
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: wish.emoji)
                .font(.system(size: 26))
            Text(verbatim: wish.title)
                .font(.appleSemiBold(size: 13))
                .foregroundStyle(Color.gray5)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let endDate = wish.endDate {
                DdayView(date: endDate)
            }
        }
        .padding(10)
        .frame(width: width, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WishHorizontalItemView_Previews: PreviewProvider {
    static var previews: some View {
        WishHorizontalItemView(wish: Wish.mockData, width: 100)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
