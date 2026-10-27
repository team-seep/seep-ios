import SwiftUI
import WidgetKit

/// 작게 쓰기: 흰 원 안 이모지 · 작은 문구 · "뭐 하고 싶어요?" · 오른쪽 아래 초록 ＋ (GH-87 R-1)
struct SmallWriteEntryView: View {
    let category: Category

    private var copy: SmallWriteCopy { SmallWriteCopy(category: category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: copy.emoji)
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Color.gray1, in: Circle())
            Spacer(minLength: 8)
            Text(verbatim: copy.caption)
                .font(.appleMedium(size: 13))
                .foregroundStyle(Color.gray4)
            Text(verbatim: copy.question)
                .font(.appleExtraBold(size: 17))
                .foregroundStyle(Color.gray5)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .widgetAccentable()
                .padding(.trailing, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background(Color.tennisGreen, in: Circle())
                .widgetAccentable()
                .padding(14)
        }
        .widgetBackground(.gray2)
        .widgetURL(copy.url)
    }
}

struct SmallWriteEntryView_Previews: PreviewProvider {
    static var previews: some View {
        SmallWriteEntryView(category: .wantToGo)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
