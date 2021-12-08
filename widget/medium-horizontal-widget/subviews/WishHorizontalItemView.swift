//
//  WishHorizontalItemView.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/12/04.
//

import SwiftUI
import WidgetKit

struct WishHorizontalItemView: View {
    let wish: Wish
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0,
            content: {
                HStack {
                    Text(wish.emoji)
                        .font(.system(size: 28))
                    
                    Spacer()
                }
                
                Text(wish.title)
                    .font(.custom("AppleSDGothicNeo-Regular", size: 14))
                    .foregroundColor(.black)
                    .padding(.top, 9)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
                Spacer()
                
                DdayView(date: self.wish.date)
            })
            .padding(.init(top: 12, leading: 12, bottom: 14, trailing: 12))
            .frame(width: (UIScreen.mediumWidgetWidth - 30 - 16) / 3)
            .background(Color.white)
            .cornerRadius(12)
            
    }
}

struct WishHorizontalItemView_Previews: PreviewProvider {
    static var previews: some View {
        WishHorizontalItemView(wish: Wish.mockData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
