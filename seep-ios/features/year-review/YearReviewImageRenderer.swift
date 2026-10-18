import UIKit

/// 회고 카드만 4:5 이미지(@3x)로 그린다 (GH-34 R-5). 닫기·버튼은 카드 밖이라 들어가지 않는다.
enum YearReviewImageRenderer {
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

        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { context in
            UIColor.gray2.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            let cardOrigin = CGPoint(
                x: (canvasSize.width - cardSize.width) / 2,
                y: (canvasSize.height - cardSize.height) / 2
            )
            cardView.drawHierarchy(in: CGRect(origin: cardOrigin, size: cardSize), afterScreenUpdates: true)
        }
    }
}
