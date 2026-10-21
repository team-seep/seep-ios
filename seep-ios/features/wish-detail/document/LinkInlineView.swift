import UIKit
import Combine

import SnapKit

/// 상세 링크 섹션 본문 (GH-59 R-6): 36pt 썸네일 + 제목 SemiBold 16/24 + 도메인 14/20 `gray4`. 행·테두리 없이 문서 톤.
/// 상태 규칙은 GH-29 `LinkPreviewCardView`와 같다 — 불러오는 중 스켈레톤, 이미지 없음 photo 심볼, 실패 link 심볼 + 안내 문구.
final class LinkInlineView: UIControl {
    private enum Layout {
        static let thumbnailSize: CGFloat = 36
        static let minHeight: CGFloat = 44
    }

    let didTapPublisher = PassthroughSubject<Void, Never>()

    private let thumbnailView = LinkThumbnailView(size: Layout.thumbnailSize, cornerRadius: 8, symbolSize: 18)

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 16)
        label.textColor = .gray5
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let domainLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let skeletonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        thumbnailView.isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityTraits = .link
        accessibilityHint = Strings.Detail.Link.openAccessibility

        [titleLabel, domainLabel].forEach(textStackView.addArrangedSubview)
        [0.8, 0.45].forEach { ratio in
            let bar = UIView()
            bar.backgroundColor = .gray2
            bar.layer.cornerRadius = 4
            skeletonStackView.addArrangedSubview(bar)
            bar.snp.makeConstraints {
                $0.width.equalTo(skeletonStackView).multipliedBy(ratio)
                $0.height.equalTo(10)
            }
        }
        addSubViews([thumbnailView, textStackView, skeletonStackView])

        snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(Layout.minHeight)
        }

        thumbnailView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(Layout.thumbnailSize)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(thumbnailView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.height.equalTo(24)
        }

        domainLabel.snp.makeConstraints {
            $0.height.equalTo(20)
        }

        skeletonStackView.snp.makeConstraints {
            $0.leading.trailing.equalTo(textStackView)
            $0.centerY.equalToSuperview()
        }

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    func bind(state: WishLinkPreviewState) {
        let isLoading: Bool
        switch state {
        case .hidden:
            isLoading = false

        case .loading:
            isLoading = true
            thumbnailView.bind(imageData: nil, placeholderSymbol: nil)

        case .loaded(let preview):
            isLoading = false
            let title = preview.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            titleLabel.text = title.isEmpty ? preview.domain : title
            domainLabel.text = preview.domain
            thumbnailView.bind(imageData: preview.imageData, placeholderSymbol: "photo")

        case .failed(let domain):
            isLoading = false
            titleLabel.text = domain
            domainLabel.text = Strings.Detail.Link.previewFailed
            thumbnailView.bind(imageData: nil, placeholderSymbol: "link")
        }

        skeletonStackView.isHidden = !isLoading
        textStackView.alpha = isLoading ? 0 : 1
        accessibilityLabel = isLoading ? nil : "\(titleLabel.text ?? ""), \(domainLabel.text ?? "")"
    }

    @objc private func didTap() {
        didTapPublisher.send(())
    }
}
