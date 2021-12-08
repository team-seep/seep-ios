//
//  EmptyView.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/12/05.
//

import SwiftUI
import WidgetKit

struct EmptyView: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("하고 싶은 것들을")
                    .font(.custom("AppleSDGothicNeo-Light", size: 22))
                    .foregroundColor(Color(r: 34, g: 34, b: 34))
                    .fixedSize()
                
                Text("적어봐요.")
                    .font(.custom("AppleSDGothicNeo-Bold", size: 22))
                    .foregroundColor(Color(r: 51, g: 51, b: 51))
                
                Text("✍️ 지금 쓰러갈까요?")
                    .padding(.init(top: 6, leading: 10, bottom: 4, trailing: 10))
                    .font(.custom("AppleSDGothicNeo-SemiBold", size: 12))
                    .foregroundColor(.black)
                    .background(Color.white)
                    .frame(height: 24)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 1)
                    .padding(.init(top: 9, leading: 0, bottom: 0, trailing: 0))
            }
            .fixedSize()
            .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 19))
            
            
            Image("img_category_want_to_do")
                .resizable()
                .aspectRatio(CGSize(width: 130, height: 125), contentMode: .fit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(r: 246, g: 247, b: 249).opacity(0.9))
    }
}

struct EmptyView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
