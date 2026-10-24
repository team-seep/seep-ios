import SwiftUI
import WidgetKit

struct MediumHorizontalEntryView: View {
    let entry: MediumHorizontalEntry

    private let horizontalPadding: CGFloat = 12
    private let itemSpacing: CGFloat = 8
    private let maxItemCount = 3

    var body: some View {
        // 기기 크기 표 대신 WidgetKit이 준 실제 위젯 크기로 아이템 폭을 계산한다
        GeometryReader { proxy in
            HStack(spacing: itemSpacing) {
                if entry.wishes.isEmpty {
                    EmptyView()
                } else {
                    ForEach(Array(entry.wishes.prefix(maxItemCount).enumerated()), id: \.offset) { _, wish in
                        WishHorizontalItemView(wish: wish, width: itemWidth(containerWidth: proxy.size.width))
                    }

                    if entry.wishes.count < maxItemCount {
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.init(top: 12, leading: horizontalPadding, bottom: 12, trailing: horizontalPadding))
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .widgetBackground(.gray2)
    }

    /// 1~2개일 때도 3칸 기준 폭을 유지한다 (기존 디자인)
    private func itemWidth(containerWidth: CGFloat) -> CGFloat {
        let totalSpacing = itemSpacing * CGFloat(maxItemCount - 1)
        let available = containerWidth - horizontalPadding * 2 - totalSpacing
        return max(0, available / CGFloat(maxItemCount))
    }
}

struct MediumHorizontalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        MediumHorizontalEntryView(entry: MediumHorizontalEntry.preview)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
