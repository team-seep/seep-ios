import UIKit

import SnapKit

/// 배지 모아보기 그리드의 칸 하나 (GH-35 R-5): `gray1` 카드, 메달 56 + 이름 + 얻은 날 또는 진행도·조건 문구.
final class BadgeCardView: UIView {
    enum Layout {
        static let height: CGFloat = 150
        static let medalSize: CGFloat = 56
    }

    private let medalView = BadgeMedalView(diameter: Layout.medalSize, fillColor: .gray2)

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 14)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(badge: Badge) {
        medalView.bind(type: badge.type, isEarned: badge.isEarned)
        nameLabel.text = badge.type.name
        nameLabel.textColor = badge.isEarned ? .gray5 : .gray4
        descriptionLabel.text = badge.earnedDateText ?? badge.lockedDescription

        isAccessibilityElement = true
        accessibilityLabel = [badge.type.name, descriptionLabel.text]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func setupUI() {
        backgroundColor = .gray1
        layer.cornerRadius = 12
        addSubViews([medalView, nameLabel, descriptionLabel])

        snp.makeConstraints {
            $0.height.equalTo(Layout.height)
        }

        medalView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.centerX.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(medalView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(8)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
    }
}
