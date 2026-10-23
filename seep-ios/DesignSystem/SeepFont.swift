import SwiftUI

/// Apple SD Gothic Neo 굵기별 폰트 이름. UIKit `UIFontExtension`과 같은 이름을 쓴다.
enum SeepFontName: String, CaseIterable {
    case ultraLight = "AppleSDGothicNeo-UltraLight"
    case light = "AppleSDGothicNeo-Light"
    case regular = "AppleSDGothicNeo-Regular"
    /// Weight: 500
    case medium = "AppleSDGothicNeo-Medium"
    case semiBold = "AppleSDGothicNeo-SemiBold"
    case bold = "AppleSDGothicNeo-Bold"
    /// Weight: 800
    case extraBold = "AppleSDGothicNeoEB00"
}

/// 싶 폰트 토큰. 앱(SwiftUI)과 위젯이 같이 쓴다 (GH-64 A-6).
extension Font {
    static func appleUltraLight(size: CGFloat) -> Font { seep(.ultraLight, size: size) }
    static func appleLight(size: CGFloat) -> Font { seep(.light, size: size) }
    static func appleRegular(size: CGFloat) -> Font { seep(.regular, size: size) }
    static func appleMedium(size: CGFloat) -> Font { seep(.medium, size: size) }
    static func appleSemiBold(size: CGFloat) -> Font { seep(.semiBold, size: size) }
    static func appleBold(size: CGFloat) -> Font { seep(.bold, size: size) }
    static func appleExtraBold(size: CGFloat) -> Font { seep(.extraBold, size: size) }

    // 디자인 시스템이 고정 크기를 쓰므로 Dynamic Type 으로 커지지 않게 fixedSize 로 만든다(지금 UIKit 화면과 같음)
    private static func seep(_ name: SeepFontName, size: CGFloat) -> Font {
        .custom(name.rawValue, fixedSize: size)
    }
}
