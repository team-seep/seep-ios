import UIKit

import SnapKit

/// 배지 메달: 원형 바탕 + 3pt 링 + 숫자·카테고리 일러스트·"D-day" (GH-35 R-1, R-5).
/// 얻은 배지는 `tennisGreen` 링, 잠긴 배지는 `gray2_5` 링에 내용을 흐리게 한다.
final class BadgeMedalView: UIView {
    enum Layout {
        static let borderWidth: CGFloat = 3
        static let lockedContentAlpha: CGFloat = 0.3
        /// 메달 지름 대비 카테고리 일러스트 크기 (56 → 36)
        static let imageRatio: CGFloat = 36 / 56
    }

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 22)
        label.textColor = .gray5
        label.textAlignment = .center
        return label
    }()

    private let ddayLabel: UILabel = {
        let label = UILabel()
        label.font = .appleExtraBold(size: 14)
        label.textColor = .gray5
        label.textAlignment = .center
        label.text = Strings.Badge.dday
        return label
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    init(diameter: CGFloat, fillColor: UIColor) {
        super.init(frame: .zero)
        setupUI(diameter: diameter, fillColor: fillColor)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(type: BadgeType, isEarned: Bool) {
        numberLabel.isHidden = true
        ddayLabel.isHidden = true
        imageView.isHidden = true

        switch type.medal {
        case .number(let number):
            numberLabel.text = "\(number)"
            numberLabel.isHidden = false
        case .category(let category):
            imageView.image = category.badgeImage
            imageView.isHidden = false
        case .dday:
            ddayLabel.isHidden = false
        }

        let contentAlpha = isEarned ? 1 : Layout.lockedContentAlpha
        [numberLabel, ddayLabel, imageView].forEach { $0.alpha = contentAlpha }
        layer.borderColor = (isEarned ? UIColor.tennisGreen : UIColor.gray2_5).cgColor
    }

    private func setupUI(diameter: CGFloat, fillColor: UIColor) {
        backgroundColor = fillColor
        layer.cornerRadius = diameter / 2
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = UIColor.gray2_5.cgColor
        isAccessibilityElement = false
        addSubViews([numberLabel, ddayLabel, imageView])

        snp.makeConstraints {
            $0.size.equalTo(diameter)
        }

        numberLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        ddayLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(round(diameter * Layout.imageRatio))
        }
    }
}

private extension Category {
    var badgeImage: UIImage {
        switch self {
        case .wantToDo:
            return Assets.Images.imgCategoryWantToDo.image
        case .wantToGet:
            return Assets.Images.imgCategoryWantToGet.image
        case .wantToGo:
            return Assets.Images.imgCategoryWantToGo.image
        }
    }
}
