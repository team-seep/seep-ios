import UIKit

/// 검색 결과 없음 안내 (GH-32 R-9)
final class WishSearchEmptyView: UIView {
    private let imageView: UIImageView = {
        let imageView = UIImageView(image: Assets.Images.imgEmojiEmpty.image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 16)
        label.textColor = .gray5
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.textAlignment = .center
        label.text = Strings.WishSearch.emptyDescription
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isHidden = true
        isUserInteractionEnabled = false
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)

        imageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(80)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(keyword: String) {
        titleLabel.text = Strings.WishSearch.emptyTitleFormat(keyword)
    }
}
