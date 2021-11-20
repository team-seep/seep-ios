import SwiftUI
import WidgetKit

struct SmallEntryView : View {
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 0,
      content: {
        HStack(alignment: .top, spacing: 0) {
          Text("😍")
            .font(.system(size: 30))
          Spacer()
        }
        .padding(.init(top: 16, leading: 16, bottom: 0, trailing: 0))
        
        HStack(alignment: .top, spacing: 0) {
          VStack(alignment: .leading, spacing: -2) {
            Text("지금")
              .multilineTextAlignment(.center)
              .font(.custom("AppleSDGothicNeoEB00", size: 20))
              .foregroundColor(.white)
            
            Rectangle()
              .fill(Color.white)
              .frame(height: 2)
          }
          .fixedSize()
          Spacer()
        }
        .offset(x: 16, y: 0)
        .padding(.top, 12)
        
        Text("뭐 하고 싶어요?")
          .foregroundColor(.white)
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
      .widgetURL(URL(string: "widget://add?category=category_want_to_do"))
  }
}


struct SmallEntryView_Previews: PreviewProvider {
  static var previews: some View {
    SmallEntryView()
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
