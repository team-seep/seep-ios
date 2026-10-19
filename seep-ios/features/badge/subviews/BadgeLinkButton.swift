import UIKit

import SnapKit

/// 링크형 텍스트 버튼 "{제목} ›" (`seepBlue`, `appleExtraBold 14`). 홈 "배지 n/8 모아보기"·축하 시트 "배지 모아보기" (GH-35 R-4, R-6)
final class BadgeLinkButton: UIControl {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleExtraBold(size: 14)
        label.textColor = .seepBlue
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView(image: Assets.Icons.icArrowRight.image.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = .seepBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1
        }
    }

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
        accessibilityLabel = title
    }

    private func setupUI() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        addSubViews([titleLabel, arrowImageView])

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        arrowImageView.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(2)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
    }
}
