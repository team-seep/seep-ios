import SwiftUI

/// 싶 색 토큰. 앱(SwiftUI)과 위젯이 같이 쓴다 — 두 타깃 멤버 (GH-64 A-6).
/// 값은 `UIColorExtension`과 같아야 한다(전환이 끝나면 UIKit 쪽을 지운다).
extension Color {
    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.init(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }

    static let gray1 = Color(r: 255, g: 255, b: 255)
    static let gray2 = Color(r: 246, g: 247, b: 249)
    static let gray2_5 = Color(r: 225, g: 227, b: 231)
    static let gray3 = Color(r: 192, g: 197, b: 205)
    static let gray4 = Color(r: 130, g: 137, b: 147)
    static let gray5 = Color(r: 51, g: 51, b: 51)

    static let seepBlue = Color(r: 47, g: 168, b: 249)
    static let optionRed = Color(r: 255, g: 92, b: 82)
    static let tennisGreen = Color(r: 102, g: 223, b: 27)
    static let optionPurple = Color(r: 231, g: 115, b: 226)

    // D-day 뱃지 색 쌍 (DdayLabel 규칙)
    static let ddayRedBg = Color(r: 255, g: 236, b: 235)
    static let ddayGreenText = Color(r: 56, g: 202, b: 79)
    static let ddayGreenBg = Color(r: 231, g: 251, b: 234)
    static let ddayBlueText = Color(r: 62, g: 163, b: 254)
    static let ddayBlueBg = Color(r: 236, g: 243, b: 250)
    static let ddayPurpleBg = Color.optionPurple.opacity(0.15)

    static let tagText = Color(r: 153, g: 153, b: 153)
    static let tagBg = Color(r: 241, g: 241, b: 241)
    static let ctaDisabled = Color(r: 204, g: 207, b: 211)
    static let emptyText = Color(r: 170, g: 170, b: 170)
}
