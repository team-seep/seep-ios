import SwiftUI
import WidgetKit

/// 중형 위젯 빈 상태: "하고 싶은 것들을 / **적어봐요.**" · 쓰러 가기 알약 · 카테고리 일러스트 (GH-87 R-3)
struct EmptyView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: WidgetEmptyCopy.title)
                    .font(.appleLight(size: 20))
                    .foregroundStyle(Color.gray5)
                    .fixedSize()
                Text(verbatim: WidgetEmptyCopy.bold)
                    .font(.appleBold(size: 20))
                    .foregroundStyle(Color.gray5)
                    .widgetAccentable()
                Text(verbatim: WidgetEmptyCopy.action)
                    .font(.appleSemiBold(size: 12))
                    .foregroundStyle(Color.gray5)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Color.gray1, in: Capsule())
                    .padding(.top, 10)
            }
            .fixedSize()
            Image("img_category_want_to_do")
                .resizable()
                .aspectRatio(CGSize(width: 130, height: 125), contentMode: .fit)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
