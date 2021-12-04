//
//  ColorExtensions.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/12/02.
//

import SwiftUI

extension Color {
    init(r: Double, g: Double, b: Double) {
        self.init(red: r/255, green: g/255, blue: b/255)
    }
    
    static let gray1 = Color(r: 255, g: 255, b: 255)
    static let gray2 = Color(r: 246, g: 247, b: 249)
    static let gray3 = Color(r: 192, g: 197, b: 205)
    static let gray4 = Color(r: 130, g: 137, b: 147)
    static let gray5 = Color(r: 51, g: 51, b: 51)
    
    static let seepBlue = Color(r: 47, g: 168, b: 249)
    static let optionRed = Color(r: 255, g: 92, b: 82)
    static let tennisGreen = Color(r: 102, g: 223, b: 27)
    static let optionPurple = Color(r: 231, g: 115, b: 226)
}
