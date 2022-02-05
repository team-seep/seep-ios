import SwiftUI
import WidgetKit

struct WishlistItemView: View {
    let wish: Wish
    
    var body: some View {
        HStack(
            alignment: .center,
            spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/,
            content: {
                if let endDate = self.wish.endDate {
                    DdayView(date: endDate)
                }
                
                Text(wish.emoji)
                    .font(.system(size: 18))
                
                Text(wish.title)
                    .font(.custom("AppleSDGothicNeo-Regular", size: 14))
                    .foregroundColor(.black)
                
                Spacer()
            })
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
    }
}

struct WishlistItemView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistItemView(wish: Wish.mockData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
