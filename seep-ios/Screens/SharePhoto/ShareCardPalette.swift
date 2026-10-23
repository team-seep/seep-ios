import Foundation
import CoreGraphics
import CoreImage
import CoreText

/// 0~1 범위 RGB. ViewModel 이 SwiftUI `Color`를 모르게 카드 바탕색을 이 값으로 들고 있는다
struct ShareCardRGB: Equatable {
    let red: Double
    let green: Double
    let blue: Double
}

/// 이모지 카드 바탕색 = 이모지 그림의 평균색을 밝게 띄운 색 (기존 `String.image()?.averageColor` 규칙과 같다)
enum ShareCardPalette {
    /// 평균색을 밝게 띄우는 값(0~255 기준). 기존 UIKit 구현과 같다
    static let brightenOffset: Double = 100
    /// 카드에 그릴 사진도 이모지도 없을 때의 바탕 (기존 photoContainer 기본색 207·164·110)
    static let fallback = ShareCardRGB(red: 207 / 255, green: 164 / 255, blue: 110 / 255)

    static func averageColor(of emoji: String) -> ShareCardRGB? {
        guard let image = renderEmoji(emoji, side: 40) else { return nil }
        let input = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: input,
            kCIInputExtentKey: CIVector(cgRect: input.extent)
        ]), let output = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        return ShareCardRGB(
            red: min(1, (Double(bitmap[0]) + brightenOffset) / 255),
            green: min(1, (Double(bitmap[1]) + brightenOffset) / 255),
            blue: min(1, (Double(bitmap[2]) + brightenOffset) / 255)
        )
    }

    /// 투명 바탕에 이모지를 그린다. 시스템 이모지 폰트(Apple Color Emoji)를 CoreText 로 직접 그린다
    static func renderEmoji(_ emoji: String, side: Int) -> CGImage? {
        guard !emoji.isEmpty,
              let context = CGContext(
                data: nil,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        let font = CTFontCreateWithName("AppleColorEmoji" as CFString, CGFloat(side) * 0.8, nil)
        let attributed = NSAttributedString(
            string: emoji,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
        )
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        context.textPosition = CGPoint(
            x: (CGFloat(side) - bounds.width) / 2 - bounds.minX,
            y: (CGFloat(side) - bounds.height) / 2 - bounds.minY
        )
        CTLineDraw(line, context)
        return context.makeImage()
    }
}
