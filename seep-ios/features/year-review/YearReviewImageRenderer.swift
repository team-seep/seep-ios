import UIKit

/// 회고 카드만 4:5 이미지(@3x)로 그린다 (GH-34 R-5). 닫기·버튼은 카드 밖이라 들어가지 않는다.
enum LegacyYearReviewImageRenderer {
    static let aspectRatio: CGFloat = 4.0 / 5.0
    static let padding: CGFloat = 24
    static let scale: CGFloat = 3

    /// 카드를 여백 안에 담는 가장 작은 4:5 캔버스 크기
    static func canvasSize(cardSize: CGSize, padding: CGFloat = padding) -> CGSize {
        let minWidth = cardSize.width + padding * 2
        let minHeight = cardSize.height + padding * 2
        let height = max(minHeight, minWidth / aspectRatio)
        return CGSize(width: height * aspectRatio, height: height)
    }

    static func render(cardView: UIView) -> UIImage {
        let cardSize = cardView.bounds.size
        let canvasSize = canvasSize(cardSize: cardSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        // 카드의 둥근 모서리 밖이 검게 칠해지지 않도록 카드는 투명 배경으로 먼저 그린 뒤 캔버스에 얹는다
        let cardFormat = UIGraphicsImageRendererFormat()
        cardFormat.scale = scale
        cardFormat.opaque = false
        let cardImage = UIGraphicsImageRenderer(size: cardSize, format: cardFormat).image { _ in
            cardView.drawHierarchy(in: CGRect(origin: .zero, size: cardSize), afterScreenUpdates: true)
        }

        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { context in
            UIColor.gray2.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            let cardOrigin = CGPoint(
                x: (canvasSize.width - cardSize.width) / 2,
                y: (canvasSize.height - cardSize.height) / 2
            )
            cardImage.draw(in: CGRect(origin: cardOrigin, size: cardSize))
        }
    }
}
