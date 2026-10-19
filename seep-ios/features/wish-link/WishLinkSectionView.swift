import UIKit
import Combine

import SnapKit

/// 위시 상세의 "링크" 섹션 (GH-29 R-4). 헤더 + 링크 카드(탭하면 Safari).
/// 링크가 없으면 접는다. 접히면 높이 0 이 되도록 위쪽 간격(24)까지 이 뷰가 갖는다.
final class WishLinkSectionView: BaseView {
    private enum Layout {
        static let topSpacing: CGFloat = 24
    }

    let didTapCardPublisher = PassthroughSubject<Void, Never>()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private let spacerView = UIView()

    private let headerView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "link")
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray5
        label.text = Strings.Detail.Link.title
        return label
    }()

    private let cardView: LinkPreviewCardView = {
        let cardView = LinkPreviewCardView()
        cardView.isChevronVisible = true
        cardView.failedMessage = Strings.Detail.Link.previewFailed
        cardView.isAccessibilityElement = true
        cardView.accessibilityTraits = .link
        cardView.accessibilityHint = Strings.Detail.Link.openAccessibility
        return cardView
    }()

    private let tapGesture = UITapGestureRecognizer()

    override func setup() {
        headerView.addSubViews([iconImageView, titleLabel])
        [spacerView, headerView, cardView].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(10, after: headerView)
        addSubview(stackView)

        cardView.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(didTapCard))
    }

    override func bindConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        spacerView.snp.makeConstraints {
            $0.height.equalTo(Layout.topSpacing)
        }

        headerView.snp.makeConstraints {
            $0.height.equalTo(16)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }
    }

    func setCollapsed(_ isCollapsed: Bool) {
        stackView.arrangedSubviews.forEach { $0.isHidden = isCollapsed }
    }

    func bind(preview: WishLinkPreviewState) {
        cardView.bind(state: preview)
    }

    @objc private func didTapCard() {
        didTapCardPublisher.send(())
    }
}
