import UIKit

import SnapKit

/// 링크 미리보기 카드 (GH-29 R-3·R-4). 썸네일 56pt + 제목 2줄 + 도메인, 테두리 `gray2_5`, 라운드 12.
/// 불러오는 중이면 스켈레톤, 실패면 링크 아이콘 + 도메인 + 안내 문구. `isChevronVisible` 이면 오른쪽에 화살표(상세에서 탭해 열기).
final class LinkPreviewCardView: BaseView {
    private enum Layout {
        static let inset: CGFloat = 12
        static let thumbnailSize: CGFloat = 56
        static let cornerRadius: CGFloat = 12
        /// 썸네일 56 + 위아래 12. 제목 2줄 + 도메인도 이 안에 들어간다
        static let height: CGFloat = 80
    }

    var isChevronVisible = false {
        didSet { chevronImageView.isHidden = !isChevronVisible }
    }

    /// 실패 카드의 안내 문구 (작성·수정과 상세가 다르다)
    var failedMessage = Strings.Write.Link.previewFailed

    private let thumbnailView = LinkThumbnailView(
        size: Layout.thumbnailSize,
        cornerRadius: Layout.cornerRadius,
        symbolSize: 24
    )

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 14)
        label.textColor = .gray5
        label.numberOfLines = 2
        return label
    }()

    private let domainLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.numberOfLines = 2
        return label
    }()

    private let skeletonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        return stackView
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .gray4
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    override func setup() {
        backgroundColor = .gray1
        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray2_5.cgColor

        [titleLabel, domainLabel].forEach(textStackView.addArrangedSubview)
        [0.9, 0.6, 0.35].forEach { ratio in
            let bar = UIView()
            bar.backgroundColor = .gray2
            bar.layer.cornerRadius = 4
            skeletonStackView.addArrangedSubview(bar)
            bar.snp.makeConstraints {
                $0.width.equalTo(skeletonStackView).multipliedBy(ratio)
                $0.height.equalTo(ratio < 0.5 ? 10 : 12)
            }
        }
        addSubViews([thumbnailView, textStackView, skeletonStackView, chevronImageView])
    }

    override func bindConstraints() {
        snp.makeConstraints {
            $0.height.equalTo(Layout.height)
        }

        thumbnailView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.inset)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(Layout.thumbnailSize)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Layout.inset)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(thumbnailView.snp.trailing).offset(Layout.inset)
            $0.trailing.equalToSuperview().offset(-40)
            $0.top.greaterThanOrEqualToSuperview().offset(Layout.inset)
            $0.bottom.lessThanOrEqualToSuperview().offset(-Layout.inset)
            $0.centerY.equalToSuperview()
        }

        skeletonStackView.snp.makeConstraints {
            $0.leading.equalTo(textStackView)
            $0.trailing.equalToSuperview().offset(-Layout.inset)
            $0.centerY.equalToSuperview()
        }
    }

    func bind(state: WishLinkPreviewState) {
        let isLoading: Bool
        switch state {
        case .hidden:
            isLoading = false

        case .loading:
            isLoading = true
            setThumbnail(imageData: nil, placeholderSymbol: nil)

        case .loaded(let preview):
            isLoading = false
            let title = preview.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            titleLabel.text = title.isEmpty ? preview.domain : title
            domainLabel.text = preview.domain
            setThumbnail(imageData: preview.imageData, placeholderSymbol: "photo")
            accessibilityLabel = "\(titleLabel.text ?? ""), \(preview.domain)"

        case .failed(let domain):
            isLoading = false
            titleLabel.text = domain
            domainLabel.text = failedMessage
            setThumbnail(imageData: nil, placeholderSymbol: "link")
            accessibilityLabel = "\(domain), \(failedMessage)"
        }

        skeletonStackView.isHidden = !isLoading
        textStackView.isHidden = isLoading
    }

    private func setThumbnail(imageData: Data?, placeholderSymbol: String?) {
        thumbnailView.bind(imageData: imageData, placeholderSymbol: placeholderSymbol)
    }
}
