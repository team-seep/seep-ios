import UIKit

import SnapKit

/// 위시 상세의 "사진" 섹션 (GH-36 R-1~R-4). 헤더(아이콘·라벨·"바꾸기") + 빈 자리(높이 120) 또는 16:9 사진 + 안내 문구.
final class WishPhotoView: BaseView {
    private enum Layout {
        static let emptyHeight: CGFloat = 120
        static let photoAspectRatio: CGFloat = 9.0 / 16.0
        static let cornerRadius: CGFloat = 12
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private let headerView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray5
        label.text = Strings.Detail.Photo.title
        return label
    }()

    let changeButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Detail.Photo.change, for: .normal)
        button.setTitleColor(.seepBlue, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        return button
    }()

    let emptyButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .gray2
        button.layer.cornerRadius = Layout.cornerRadius
        return button
    }()

    private let emptyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 6
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 14)
        label.textColor = .seepBlue
        label.text = Strings.Detail.Photo.add
        return label
    }()

    private let emptyDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.text = Strings.Detail.Photo.addDescription
        return label
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.cornerRadius
        imageView.backgroundColor = .gray2
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.text = Strings.Detail.Photo.caption
        return label
    }()

    override func setup() {
        headerView.addSubViews([iconImageView, titleLabel, changeButton])
        [emptyTitleLabel, emptyDescriptionLabel].forEach(emptyStackView.addArrangedSubview)
        emptyButton.addSubview(emptyStackView)

        [headerView, emptyButton, photoImageView, captionLabel].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(10, after: headerView)
        stackView.setCustomSpacing(8, after: photoImageView)
        addSubview(stackView)

        bind(image: nil)
    }

    override func bindConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.height.equalTo(20)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }

        changeButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.height.equalTo(44)
        }

        emptyButton.snp.makeConstraints {
            $0.height.equalTo(Layout.emptyHeight)
        }

        emptyStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        photoImageView.snp.makeConstraints {
            $0.height.equalTo(photoImageView.snp.width).multipliedBy(Layout.photoAspectRatio)
        }
    }

    /// 사진 파일을 읽지 못하면(파일 없음·손상) 빈 상태로 보여준다 (R-7).
    func bind(photoURL: URL?) {
        bind(image: photoURL.flatMap { UIImage(contentsOfFile: $0.path) })
    }

    private func bind(image: UIImage?) {
        let hasPhoto = image != nil
        photoImageView.image = image
        photoImageView.isHidden = !hasPhoto
        captionLabel.isHidden = !hasPhoto
        changeButton.isHidden = !hasPhoto
        emptyButton.isHidden = hasPhoto
    }
}
