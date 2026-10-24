import SwiftUI
import WidgetKit

/// 중형 세로 한 줄: D-day · 이모지 18 · 제목 SemiBold 13. 체크 위젯 줄과 같은 틀 (GH-87 R-1)
struct WishlistItemView: View {
    let wish: Wish

    var body: some View {
        HStack(spacing: 7) {
            if let endDate = wish.endDate {
                DdayView(date: endDate)
            }
            Text(verbatim: wish.emoji)
                .font(.system(size: 18))
            Text(verbatim: wish.title)
                .font(.appleSemiBold(size: 13))
                .foregroundStyle(Color.gray5)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct WishlistItemView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistItemView(wish: Wish.mockData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
