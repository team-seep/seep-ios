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
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("하고 싶은 것들을")
                    .font(.custom("AppleSDGothicNeo-Light", size: 22))
                    .foregroundColor(Color(r: 34, g: 34, b: 34))
                
                Text("적어봐요.")
                    .font(.custom("AppleSDGothicNeo-Bold", size: 22))
                    .foregroundColor(Color(r: 51, g: 51, b: 51))
            }
            .padding(.init(top: 0, leading: 20, bottom: 0, trailing: 0))
            
            Image("img_category_want_to_do")
                .frame(width: 130, height: 125, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
