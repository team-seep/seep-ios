//
//  DdayView.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/12/04.
//

import SwiftUI
import WidgetKit

struct DdayView: View {
    let date: Date
    
    var body: some View {
        Text(self.getDday(dday: self.date))
            .font(.custom("AppleSDGothicNeo-Bold", size: 12))
            .padding(.init(top: 3, leading: 6, bottom: 1, trailing: 7))
            .foregroundColor(self.getTextColor(dday: self.date))
            .background(self.getBackground(dday: self.date))
            .cornerRadius(4)
    }
    
    private func getDday(dday: Date) -> String {
        let remainDay = Calendar.current.dateComponents([.day], from: Date().startOfDay, to: dday.startOfDay).day ?? -1
        
        if remainDay < 0 {
          return "D+\(abs(remainDay))"
        } else if remainDay <= 365 {
          return "D-\(remainDay)"
        } else {
          return "먼훗날"
        }
    }
    
    private func getBackground(dday: Date) -> Color {
        let remainDay = Calendar.current.dateComponents([.day], from: Date().startOfDay, to: dday.startOfDay).day ?? -1
        
        switch remainDay {
        case _ where remainDay < 0:
            return .optionPurple.opacity(0.15)
            
        case 0..<8:
            return Color(r: 255, g: 236, b: 235)
            
        case 8..<31:
            return Color(r: 231, g: 251, b: 234)
            
        default:
            return Color(r: 236, g: 243, b: 250)
        }
    }
    
    private func getTextColor(dday: Date) -> Color {
        let remainDay = Calendar.current.dateComponents([.day], from: Date().startOfDay, to: dday.startOfDay).day ?? -1
        
        switch remainDay {
        case _ where remainDay < 0:
            return .optionPurple
            
        case 0..<8:
            return .optionRed
            
        case 8..<31:
            return Color(r: 56, g: 202, b: 79)
            
        default:
            return Color(r: 62, g: 163, b: 254)
        }
    }
}

struct DdayView_Previews: PreviewProvider {
    static var previews: some View {
        DdayView(date: Date())
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
