import SwiftUI
import WidgetKit

/// 중형 세로: 최대 3줄, 체크 위젯과 같은 여백·간격 (GH-87 R-1, R-3)
struct MediumVerticalEntryView: View {
    let entry: MediumVerticalEntry

    var body: some View {
        Group {
            if entry.wishes.isEmpty {
                EmptyView()
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.wishes.prefix(3), id: \.id) { wish in
                        WishlistItemView(wish: wish)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.init(top: 12, leading: 15, bottom: 12, trailing: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(.gray2)
    }
}

struct MediumEntryView_Previews: PreviewProvider {
    static var previews: some View {
        MediumVerticalEntryView(entry: MediumVerticalEntry.preview)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
