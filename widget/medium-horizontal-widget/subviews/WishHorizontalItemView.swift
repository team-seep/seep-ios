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
    /// 위젯 실제 폭에서 계산한 아이템 폭. 기기별 표로 정하면 표에 없는 기기(듀오 등)에서 어긋난다.
    let width: CGFloat
    
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
                
                if let deadline = self.wish.endDate {
                    DdayView(date: deadline)
                }
            })
            .padding(.init(top: 12, leading: 12, bottom: 14, trailing: 12))
            .frame(width: width)
            .background(Color.white)
            .cornerRadius(12)
            
    }
}

struct WishHorizontalItemView_Previews: PreviewProvider {
    static var previews: some View {
        WishHorizontalItemView(wish: Wish.mockData, width: 100)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
