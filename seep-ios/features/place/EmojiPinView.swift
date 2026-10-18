import UIKit

import SnapKit

/// 위시 이모지를 담은 동그란 지도 핀 (GH-31). 지도 화면 핀과 상세 지도 미리보기가 같이 쓴다.
/// 선택되면 커지고 테두리가 seepBlue 가 된다 (R-7).
final class EmojiPinView: UIView {
    enum Layout {
        static let normalSize: CGFloat = 40
        static let selectedSize: CGFloat = 52
        static let tailSize: CGFloat = 8

        static func size(isSelected: Bool) -> CGSize {
            let diameter = isSelected ? selectedSize : normalSize
            return CGSize(width: diameter, height: diameter + tailSize / 2)
        }
    }

    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.gray2_5.cgColor
        return view
    }()

    private let tailView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        view.transform = CGAffineTransform(rotationAngle: .pi / 4)
        return view
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private(set) var isPinSelected = false

    init(emoji: String, isSelected: Bool = false) {
        super.init(frame: CGRect(origin: .zero, size: Layout.size(isSelected: isSelected)))
        setup()
        emojiLabel.text = emoji
        setSelected(isSelected)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ isSelected: Bool) {
        isPinSelected = isSelected
        let diameter = isSelected ? Layout.selectedSize : Layout.normalSize
        frame.size = Layout.size(isSelected: isSelected)
        circleView.frame = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        circleView.layer.cornerRadius = diameter / 2
        circleView.layer.borderWidth = isSelected ? 3 : 2
        circleView.layer.borderColor = (isSelected ? UIColor.seepBlue : UIColor.gray2_5).cgColor
        tailView.backgroundColor = isSelected ? .seepBlue : .gray2_5
        tailView.bounds = CGRect(x: 0, y: 0, width: Layout.tailSize, height: Layout.tailSize)
        tailView.center = CGPoint(x: diameter / 2, y: diameter)
        emojiLabel.font = .systemFont(ofSize: diameter * 0.5)
        emojiLabel.frame = circleView.bounds
    }

    private func setup() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.gray5.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubViews([tailView, circleView])
        circleView.addSubview(emojiLabel)
    }
}
