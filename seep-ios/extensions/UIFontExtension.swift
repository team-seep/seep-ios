import UIKit

extension UIFont {
    
    static func appleLight(size: CGFloat) -> UIFont? {
        return UIFont(name: "AppleSDGothicNeo-Light", size: size)
    }
    
    static func appleRegular(size: CGFloat) -> UIFont? {
        return UIFont(name: "AppleSDGothicNeo-Regular", size: size)
    }
    
    /// Weight: 500
    static func appleMedium(size: CGFloat) -> UIFont? {
        return UIFont(name: "AppleSDGothicNeo-Medium", size: size)
    }
    
    static func appleSemiBold(size: CGFloat) -> UIFont? {
        return UIFont(name: "AppleSDGothicNeo-SemiBold", size: size)
    }
    
    static func appleBold(size: CGFloat) -> UIFont? {
        return UIFont(name: "AppleSDGothicNeo-Bold", size: size)
    }
    
    /// Weight: 800
    static func appleExtraBold(size: CGFloat) -> UIFont? {
        return UIFont(name: "AppleSDGothicNeoEB00", size: size)
    }
    
    static func appleUltraLight(size: CGFloat) -> UIFont? {
        return UIFont(name: "AppleSDGothicNeo-UltraLight", size: size)
    }
}

/// 글자 크기 + 줄 높이 묶음. 상세 문서(GH-59)의 `doc-title` Bold 26/36, `doc-body` Regular 16/28.
enum SeepTextStyle {
    case docTitle
    case docBody

    var font: UIFont? {
        switch self {
        case .docTitle:
            return .appleBold(size: 26)
        case .docBody:
            return .appleRegular(size: 16)
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .docTitle:
            return 36
        case .docBody:
            return 28
        }
    }

    func attributes(color: UIColor, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineBreakMode = lineBreakMode
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        if let font {
            attributes[.font] = font
            // 줄 높이를 늘리면 글자가 줄 아래에 붙어 위아래 가운데로 옮긴다
            attributes[.baselineOffset] = (lineHeight - font.lineHeight) / 4
        }
        return attributes
    }

    func attributedString(_ text: String, color: UIColor, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: attributes(color: color, lineBreakMode: lineBreakMode))
    }
}
