import SwiftUI
import WidgetKit

struct SmallEntryView : View {
  
  let categoryData: SmallWidgetData
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 0,
      content: {
        HStack(alignment: .top, spacing: 0) {
          Text(self.categoryData.emoji)
            .font(.system(size: 30))
          Spacer()
        }
        .padding(.init(top: 16, leading: 16, bottom: 0, trailing: 0))
        
        HStack(alignment: .top, spacing: 0) {
          VStack(alignment: .leading, spacing: -2) {
            Text(self.categoryData.title)
              .font(.custom("AppleSDGothicNeoEB00", size: 20))
              .foregroundColor(.white)
            
            Rectangle()
              .fill(Color.white)
              .frame(height: 2)
          }
          .fixedSize()
          Spacer()
        }
        .padding(.init(top: 8, leading: 16, bottom: 0, trailing: 0))
        
        Text(self.categoryData.description)
          .foregroundColor(.white)
          .multilineTextAlignment(.leading)
          .font(Font.custom("AppleSDGothicNeo-Light", size: 20))
          .padding(.init(top: 4, leading: 16, bottom: 0, trailing: 0))
        
        Spacer()
      })
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(
        .sRGB,
        red: 102/255,
        green: 223/255,
        blue: 27/255,
        opacity: 1
      ))
      .widgetURL(URL(string: self.categoryData.deepLink))
  }
}


struct SmallEntryView_Previews: PreviewProvider {
  static var previews: some View {
    SmallEntryView(categoryData: .init(category: .wantToGo))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
