import SwiftUI

/// 싶 색 토큰. 앱(SwiftUI)과 위젯이 같이 쓴다 — 두 타깃 멤버 (GH-64 A-6).
/// 회색·뱃지·보조 색은 `SeepColors.xcassets`에 라이트/다크 두 값을 둔다(GH-85 R-1). 브랜드 색은 두 모드에서 같다
extension Color {
    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.init(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }

    static let gray1 = Color("seepGray1")
    static let gray2 = Color("seepGray2")
    static let gray2_5 = Color("seepGray2_5")
    static let gray3 = Color("seepGray3")
    static let gray4 = Color("seepGray4")
    static let gray5 = Color("seepGray5")

    /// 파랑·초록·빨강 바탕 위 흰 글자·체크. 다크에서도 흰색이다 (GH-85)
    static let onAccent = Color(r: 255, g: 255, b: 255)

    static let seepBlue = Color(r: 47, g: 168, b: 249)
    static let optionRed = Color(r: 255, g: 92, b: 82)
    static let tennisGreen = Color(r: 102, g: 223, b: 27)
    static let optionPurple = Color(r: 231, g: 115, b: 226)

    // D-day 뱃지 색 쌍 (DdayLabel 규칙)
    static let ddayRedBg = Color("seepDdayRedBg")
    static let ddayGreenText = Color("seepDdayGreenText")
    static let ddayGreenBg = Color("seepDdayGreenBg")
    static let ddayBlueText = Color("seepDdayBlueText")
    static let ddayBlueBg = Color("seepDdayBlueBg")
    static let ddayPurpleBg = Color.optionPurple.opacity(0.15)

    static let tagText = Color("seepTagText")
    static let tagBg = Color("seepTagBg")
    static let ctaDisabled = Color("seepCtaDisabled")
    static let emptyText = Color("seepEmptyText")
    /// 작성·수정 화면 카테고리 선택 트랙 배경 (디자인 시스템 category-track)
    static let categoryTrack = Color("seepCategoryTrack")
    /// 작성 화면 카테고리 비선택 텍스트 (디자인 시스템 category-text-off)
    static let categoryTextOff = Color("seepCategoryTextOff")
}
