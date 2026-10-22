import UIKit

import SnapKit

/// 링크 미리보기 썸네일 (GH-29 규칙, GH-59에서 분리). `gray2` 칸 위에 이미지(aspectFill) 또는 `gray3` 심볼.
/// 링크 카드(`LinkPreviewCardView`, 56·라운드 12·심볼 24)와 상세 링크 줄(`LinkInlineView`, 36·라운드 8·심볼 18)이 같이 쓴다.
final class LinkThumbnailView: UIView {
    private let size: CGFloat

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .gray3
        return imageView
    }()

    init(size: CGFloat, cornerRadius: CGFloat, symbolSize: CGFloat) {
        self.size = size
        super.init(frame: .zero)
        backgroundColor = .gray2
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        addSubViews([placeholderImageView, imageView])

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        placeholderImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(symbolSize)
        }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: size, height: size)
    }

    /// 이미지가 없으면 심볼(없으면 빈 칸)을 보인다. 불러오는 중은 둘 다 nil
    func bind(imageData: Data?, placeholderSymbol: String?) {
        let image = imageData.flatMap(UIImage.init(data:))
        imageView.image = image
        imageView.isHidden = image == nil
        placeholderImageView.image = placeholderSymbol.flatMap { UIImage(systemName: $0) }
        placeholderImageView.isHidden = image != nil
    }
}
