import SwiftUI

/// 회고 카드만 4:5 이미지(@3x)로 그린다 (GH-34 R-5). 닫기·버튼은 카드 밖이라 들어가지 않는다
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

    /// 카드 폭을 화면과 같게 두고 gray2 캔버스 가운데에 얹어 그린다. 그리지 못하면 nil
    @MainActor
    static func render(summary: YearReviewSummary, cardWidth: CGFloat) -> Image? {
        // 공유 이미지는 화면 모드와 상관없이 라이트로 만든다 (GH-85 R-6)
        let card = YearReviewCard(summary: summary)
            .frame(width: cardWidth)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.colorScheme, .light)

        // 1배로 한 번 그려 카드의 실제 높이(pt)를 얻는다
        let measuring = ImageRenderer(content: card)
        measuring.scale = 1
        guard let measured = measuring.cgImage, measured.width > 0, measured.height > 0 else { return nil }
        let canvas = canvasSize(cardSize: CGSize(width: measured.width, height: measured.height))

        let renderer = ImageRenderer(content: ZStack {
            Color.gray2
            card
        }
        .frame(width: canvas.width, height: canvas.height)
        .environment(\.colorScheme, .light))
        renderer.scale = scale
        renderer.isOpaque = true
        guard let cgImage = renderer.cgImage else { return nil }
        return Image(decorative: cgImage, scale: scale)
    }
}
