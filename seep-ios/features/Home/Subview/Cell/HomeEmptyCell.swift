import UIKit

final class HomeEmptyCell: BaseCollectionViewCell {
    enum Layout {
        static let size = CGSize(width: UIUtils.windowBounds.width - 40, height: 246)
    }
    
    let emptyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(r: 170, g: 170, b: 170)
        label.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle().then {
            $0.lineHeightMultiple = 1.5
        }
        let attributedText = NSMutableAttributedString(
            string: Strings.Home.empty,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.appleMedium(size: 12) as Any
            ])
        label.attributedText = attributedText
        label.textAlignment = .center
        return label
    }()
    
    
    override func setup() {
        contentView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}
