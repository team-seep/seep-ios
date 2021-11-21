import SwiftUI
import WidgetKit

struct SmallRemainEntryView: View {
  
  let categoryData: SmallRemainWidgetData
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0, content: {
      HStack(alignment: .top, spacing: 0, content: {
        Text(self.categoryData.title)
          .font(.custom("AppleSDGothicNeo-Light", size: 18))
          .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
        
        Spacer()
      })
      
      VStack(alignment: .leading, spacing: -2, content: {
        Text(self.categoryData.description)
          .font(.custom("AppleSDGothicNeo-Bold", size: 22))
          .foregroundColor(Color(red: 102/255, green: 223/255, blue: 27/255))
        
        Rectangle()
          .foregroundColor(Color(red: 102/255, green: 223/255, blue: 27/255))
          .frame(height: 2)
      })
      .fixedSize()
      .padding(.top, 4)
      
      Text("남았어요!")
        .font(.custom("AppleSDGothicNeo-Bold", size: 22))
        .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
        .padding(.top, 10)
      
      Spacer()
    })
    .padding(.init(top: 16, leading: 16, bottom: 0, trailing: 0))
    .widgetURL(URL(string: self.categoryData.deepLink))
  }
}

struct SmallRemainEntryView_Previews: PreviewProvider {
  static var previews: some View {
    SmallRemainEntryView(categoryData: .init(category: .wantToDo, count: 2))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
