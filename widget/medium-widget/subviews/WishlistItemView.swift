import SwiftUI
import WidgetKit

struct WishlistItemView: View {
    var body: some View {
      HStack(
        alignment: .center,
        spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/,
        content: {
          Image("ic_check_off_20")
            .padding(.trailing, 13)
          
          Text("D-2")
            .font(.custom("AppleSDGothicNeo-Bold", size: 12))
            .foregroundColor(Color(red: 1, green: 0.36, blue: 0.32))
            .padding(.init(top: 3, leading: 6, bottom: 1, trailing: 7))
            .background(Color(red: 1, green: 0.92, blue: 0.92, opacity: 1))
            .cornerRadius(4)
            .padding(.trailing, 11)
          
          Text("단양가서 패러글라이딩 하기")
            .font(.custom("AppleSDGothicNeo-Regular", size: 14))
            .foregroundColor(.black)
      })
    }
}

struct WishlistItemView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistItemView()
          .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
