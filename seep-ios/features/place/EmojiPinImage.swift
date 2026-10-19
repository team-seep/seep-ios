import UIKit

/// 위시 이모지를 담은 동그란 지도 핀 이미지 (GH-31). 지도 화면 핀과 상세 지도 미리보기가 같이 쓴다.
/// 선택되면 커지고 테두리가 seepBlue 가 된다 (R-7). 꼬리 끝이 이미지 아래쪽 가운데다.
enum EmojiPinImage {
    enum Layout {
        static let normalDiameter: CGFloat = 40
        static let selectedDiameter: CGFloat = 52
        /// 원 아래로 나오는 꼬리 길이
        static let tailLength: CGFloat = 6
    }

    static func make(emoji: String, isSelected: Bool) -> UIImage {
        let diameter = isSelected ? Layout.selectedDiameter : Layout.normalDiameter
        let borderWidth: CGFloat = isSelected ? 3 : 2
        let borderColor: UIColor = isSelected ? .seepBlue : .gray2_5
        let size = CGSize(width: diameter, height: diameter + Layout.tailLength)

        return UIGraphicsImageRenderer(size: size).image { _ in
            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: diameter / 2 - 6, y: diameter - 4))
            tail.addLine(to: CGPoint(x: diameter / 2 + 6, y: diameter - 4))
            tail.addLine(to: CGPoint(x: diameter / 2, y: size.height))
            tail.close()
            borderColor.setFill()
            tail.fill()

            let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: diameter, height: diameter)
                .insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
            UIColor.white.setFill()
            circle.fill()
            circle.lineWidth = borderWidth
            borderColor.setStroke()
            circle.stroke()

            let text = NSAttributedString(string: emoji, attributes: [.font: UIFont.systemFont(ofSize: diameter * 0.5)])
            let textSize = text.size()
            text.draw(at: CGPoint(x: (diameter - textSize.width) / 2, y: (diameter - textSize.height) / 2))
        }
    }
}
