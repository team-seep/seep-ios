import UIKit

import SnapKit

/// 장소 검색 후보 한 줄: 핀 아이콘 · 이름 · 주소 (GH-31 R-3)
final class PlaceSearchResultCell: BaseTableViewCell {
    static let registerId = "\(PlaceSearchResultCell.self)"

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.and.ellipse")
        imageView.tintColor = .gray4
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 16)
        label.textColor = .gray5
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        return label
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        return view
    }()

    override func setup() {
        backgroundColor = .white
        selectionStyle = .none
        contentView.addSubViews([iconImageView, titleLabel, subtitleLabel, dividerView])
    }

    override func bindConstraints() {
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(14)
        }

        subtitleLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().inset(14)
        }

        dividerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    func bind(candidate: PlaceCandidate) {
        titleLabel.text = candidate.title
        subtitleLabel.text = candidate.subtitle
        subtitleLabel.isHidden = candidate.subtitle.isEmpty
    }
}
