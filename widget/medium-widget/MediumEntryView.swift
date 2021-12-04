import SwiftUI
import WidgetKit

struct MediumEntryView: View {
    let entry: MediumEntry
    
    var body: some View {
        VStack {
            VStack {
                if entry.wishes.isEmpty {
                    
                } else {
                    if entry.wishes.count == 1 {
                        WishlistItemView(wish: entry.wishes[0])
                        
                        Spacer()
                    } else if entry.wishes.count == 2 {
                        WishlistItemView(wish: entry.wishes[0])
                        WishlistItemView(wish: entry.wishes[1])
                        
                        Spacer()
                    } else {
                        WishlistItemView(wish: entry.wishes[0])
                        WishlistItemView(wish: entry.wishes[1])
                        WishlistItemView(wish: entry.wishes[2])
                    }
                }
            }
            .padding(.init(top: 12, leading: 15, bottom: 12, trailing: 15))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(r: 246, g: 247, b: 249))
    }
}

struct MediumEntryView_Previews: PreviewProvider {
    static var previews: some View {
        MediumEntryView(entry: MediumEntry.preview)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
