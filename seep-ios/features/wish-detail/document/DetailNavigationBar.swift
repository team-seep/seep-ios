import UIKit

import SnapKit

/// 상세 상단 바 (GH-59 R-8): 뒤로 · [축소 제목 + 작은 D-day] · "수정" · ⋯.
/// 스크롤해 큰 제목이 지나가면 가운데에 제목(말줄임)과 D-day(ExtraBold 13, 색만, 잘리지 않음)를 보이고 아래 1pt 선을 긋는다.
final class DetailNavigationBar: UIView {
    static let height: CGFloat = 44

    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icChevronBack.image, for: .normal)
        button.accessibilityLabel = Strings.Detail.Nav.back
        return button
    }()

    let editButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Detail.Nav.edit, for: .normal)
        button.setTitleColor(.seepBlue, for: .normal)
        button.setTitleColor(.seepBlue.withAlphaComponent(0.4), for: .highlighted)
        button.titleLabel?.font = .appleExtraBold(size: 14)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        return button
    }()

    let moreButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icMore.image, for: .normal)
        button.accessibilityLabel = Strings.Detail.Nav.more
        return button
    }()

    private let rightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()

    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        stackView.alpha = 0
        stackView.isAccessibilityElement = true
        stackView.accessibilityTraits = .header
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 16)
        label.textColor = .gray5
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let ddayLabel: UILabel = {
        let label = UILabel()
        label.font = .appleExtraBold(size: 13)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        view.alpha = 0
        return view
    }()

    private(set) var isTitleCollapsed = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .gray1
        [editButton, moreButton].forEach(rightStackView.addArrangedSubview)
        [titleLabel, ddayLabel].forEach(titleStackView.addArrangedSubview)
        addSubViews([backButton, titleStackView, rightStackView, separatorView])

        snp.makeConstraints {
            $0.height.equalTo(Self.height)
        }

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        rightStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-10)
            $0.centerY.equalToSuperview()
        }

        editButton.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.width.greaterThanOrEqualTo(44)
        }

        moreButton.snp.makeConstraints {
            $0.size.equalTo(44)
        }

        titleStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().priority(.high)
            $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualTo(rightStackView.snp.leading).offset(-8)
        }

        separatorView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    /// 축소 헤더 문구. `dday` 가 nil(일정없음·먼훗날)이면 제목만 (R-8)
    func setTitle(_ title: String, dday: WishDetailSummary.DdayLine?) {
        titleLabel.text = title
        ddayLabel.text = dday?.text
        ddayLabel.textColor = dday?.tone.textColor
        ddayLabel.isHidden = dday == nil
        titleStackView.accessibilityLabel = [title, dday?.text].compactMap { $0 }.joined(separator: ", ")
    }

    func setEditVisible(_ isVisible: Bool) {
        editButton.isHidden = !isVisible
    }

    func setTitleCollapsed(_ isCollapsed: Bool) {
        guard isCollapsed != isTitleCollapsed else { return }
        isTitleCollapsed = isCollapsed
        UIView.animate(withDuration: 0.2) {
            self.titleStackView.alpha = isCollapsed ? 1 : 0
            self.separatorView.alpha = isCollapsed ? 1 : 0
        }
    }
}
