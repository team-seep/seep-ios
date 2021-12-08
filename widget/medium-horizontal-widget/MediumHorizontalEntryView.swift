import SwiftUI
import WidgetKit

struct MediumHorizontalEntryView: View {
    let entry: MediumHorizontalEntry
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                if entry.wishes.isEmpty {
                    EmptyView()
                } else {
                    if entry.wishes.count == 1 {
                        WishHorizontalItemView(wish: entry.wishes[0])
                        
                        Spacer()
                    } else if entry.wishes.count == 2 {
                        WishHorizontalItemView(wish: entry.wishes[0])
                        WishHorizontalItemView(wish: entry.wishes[1])
                        
                        Spacer()
                    } else {
                        WishHorizontalItemView(wish: entry.wishes[0])
                        WishHorizontalItemView(wish: entry.wishes[1])
                        WishHorizontalItemView(wish: entry.wishes[2])
                    }
                }
            }
            .padding(.init(top: 14, leading: 15, bottom: 14, trailing: 15))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(r: 246, g: 247, b: 249))
    }
}

struct MediumHorizontalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        MediumHorizontalEntryView(entry: MediumHorizontalEntry.preview)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
