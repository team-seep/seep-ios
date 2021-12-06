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
            spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/,
            content: {
                Text(wish.emoji)
                    .font(.system(size: 28))
                
                Text(wish.title)
                    .font(.custom("AppleSDGothicNeo-Regular", size: 14))
                    .foregroundColor(.black)
                    .padding(.top, 5)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
                DdayView(date: self.wish.date)
                    .padding(.top, 9)
                
                Spacer()
            })
            .padding(12)
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
