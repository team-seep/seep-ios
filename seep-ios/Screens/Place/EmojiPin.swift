import SwiftUI

/// 위시 이모지를 담은 동그란 지도 핀 (GH-31 R-7). 선택되면 커지고 테두리가 seepBlue 가 된다.
/// 꼬리 끝이 아래쪽 가운데라 `Annotation(anchor: .bottom)`으로 좌표에 맞춘다
struct EmojiPin: View {
    enum Layout {
        static let normalDiameter: CGFloat = 40
        static let selectedDiameter: CGFloat = 52
        /// 원 아래로 나오는 꼬리 길이
        static let tailLength: CGFloat = 6
    }

    let emoji: String
    let isSelected: Bool

    private var diameter: CGFloat { isSelected ? Layout.selectedDiameter : Layout.normalDiameter }
    private var borderWidth: CGFloat { isSelected ? 3 : 2 }
    private var borderColor: Color { isSelected ? .seepBlue : .gray2_5 }

    var body: some View {
        ZStack(alignment: .top) {
            PinTail()
                .fill(borderColor)
                .frame(width: 12, height: Layout.tailLength + 4)
                .offset(y: diameter - 4)
            Circle()
                .fill(Color.gray1)
                .overlay {
                    Circle().strokeBorder(borderColor, lineWidth: borderWidth)
                }
                .overlay {
                    Text(verbatim: emoji)
                        .font(.system(size: diameter * 0.5))
                }
                .frame(width: diameter, height: diameter)
        }
        .frame(width: diameter, height: diameter + Layout.tailLength, alignment: .top)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

/// 원 아래 역삼각형 꼬리
private struct PinTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
