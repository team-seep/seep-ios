import SwiftUI
import WidgetKit

struct MediumEntryView: View {
  var body: some View {
    ZStack {
      Color.white
      
      VStack(
        alignment: .leading,
        spacing: nil,
        content: {
          WishlistItemView()
            .padding(.leading, 14)
          
          Divider()
            .border(Color(red: 0.93, green: 0.93, blue: 0.93), width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .padding(.horizontal, 15)
          
          WishlistItemView()
            .padding(.leading, 14)
          
          Divider()
            .border(Color(red: 0.93, green: 0.93, blue: 0.93), width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .padding(.horizontal, 15)
          
          WishlistItemView()
            .padding(.leading, 14)
        })
    }
  }
}

struct MediumEntryView_Previews: PreviewProvider {
  static var previews: some View {
    MediumEntryView()
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
