import UIKit

import SnapKit

/// 지도에서 핀을 고르면 아래에 뜨는 위시 카드: 이모지 · 제목 · D-day · 장소 이름 (GH-31 R-7)
final class PlaceMapWishCardView: UIControl {
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 16)
        label.textColor = .gray5
        return label
    }()

    private let ddayLabel = DdayLabel()

    private let placeLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .gray4
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(wish: Wish) {
        emojiLabel.text = wish.emoji
        titleLabel.text = wish.title
        ddayLabel.bind(dday: wish.endDate)
        placeLabel.text = wish.place?.name
        accessibilityLabel = [wish.title, ddayLabel.text, wish.place?.name].compactMap { $0 }.joined(separator: ", ")
    }

    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.gray5.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        isAccessibilityElement = true
        accessibilityTraits = .button

        [emojiLabel, titleLabel, ddayLabel, placeLabel, chevronImageView].forEach {
            $0.isUserInteractionEnabled = false
            addSubview($0)
        }

        emojiLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(18)
        }

        ddayLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.bottom.equalToSuperview().inset(18)
        }

        placeLabel.snp.makeConstraints {
            $0.leading.equalTo(ddayLabel.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalTo(ddayLabel)
        }
        ddayLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}
