import SwiftUI
import WidgetKit

/// 남은 개수: "하고 싶은 것들이" · 큰 숫자 + "개 남았어요!" · 가장 가까운 위시 한 줄 (GH-87 R-1, R-3)
struct SmallRemainEntryView: View {
    let entry: SmallRemainEntry

    var body: some View {
        let copy = entry.copy
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: copy.headline)
                .font(.appleMedium(size: 13))
                .foregroundStyle(Color.gray4)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(verbatim: copy.count)
                    .font(.appleExtraBold(size: 40))
                    .foregroundStyle(Color.tennisGreen)
                    .widgetAccentable()
                Text(verbatim: copy.suffix)
                    .font(.appleExtraBold(size: 15))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 6)
            nextLine(copy: copy)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .widgetBackground(.gray2)
        .widgetURL(copy.url)
    }

    @ViewBuilder
    private func nextLine(copy: SmallRemainCopy) -> some View {
        HStack(spacing: 6) {
            if let wish = entry.nextWish {
                if let endDate = wish.endDate {
                    DdayView(date: endDate)
                }
                Text(verbatim: wish.emoji)
                    .font(.system(size: 14))
                Text(verbatim: wish.title)
                    .font(.appleSemiBold(size: 12))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
            } else {
                Text(verbatim: copy.emptyCaption ?? "")
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.gray4)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 34)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct SmallRemainEntryView_Previews: PreviewProvider {
    static var previews: some View {
        SmallRemainEntryView(entry: .init(date: Date(), category: .wantToDo, count: 2, nextWish: Wish.mockData))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
