import SwiftUI
import WidgetKit

struct SmallEntryView : View {
  
  var body: some View {
    ZStack {
      Color.white
      
      VStack(
        alignment: .center,
        spacing: 16,
        content: {
          Text("당신은 지금\n뭐하고 싶어요?")
            .multilineTextAlignment(.center)
            .font(.system(size: 14))
            .foregroundColor(.black)
          
          VStack {
            Text("생성하기")
              .foregroundColor(.white)
              .font(Font.custom("AppleSDGothicNeoEB00", size: 11))
              .padding(.init(top: 8, leading: 16, bottom: 6, trailing: 16))
              .background(Color(red: 0.4, green: 0.87, blue: 0.1))
              .cornerRadius(14)
          }
      })
    }
    .widgetURL(URL(string: "widget://add"))
  }
}


struct SmallEntryView_Previews: PreviewProvider {
  static var previews: some View {
    SmallEntryView()
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
