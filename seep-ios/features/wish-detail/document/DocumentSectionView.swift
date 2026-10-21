import UIKit

import SnapKit

/// 문서 안의 파란 글자 버튼 (GH-59 R-6·R-8). 글자는 줄 높이에 맞추고 터치 영역만 44pt로 넓힌다.
/// "파란 글자가 있는 곳만 누른다" — 보기 전용 영역에는 쓰지 않는다 (R-7).
final class TextActionButton: UIButton {
    static let touchHeight: CGFloat = 44

    init(title: String, font: UIFont? = .appleMedium(size: 14)) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.seepBlue, for: .normal)
        setTitleColor(.seepBlue.withAlphaComponent(0.4), for: .highlighted)
        titleLabel?.font = font
        contentHorizontalAlignment = .trailing
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 문서 섹션: 얇은 제목(`gray4`) + 선택 숫자(`gray5` Bold) + 선택 액션(파란 글자) + 내용 (GH-59 R-6).
/// 카드·구분선 없이 위 섹션과 40pt 여백으로 나눈다(간격은 상세 뷰 스택이 준다).
final class DocumentSectionView: UIView {
    private enum Layout {
        static let headerHeight: CGFloat = 22
        static let contentSpacing: CGFloat = 10
        /// 헤더(22) 위아래로 터치 영역을 넓혀 액션 버튼이 44pt가 되게 한다
        static let headerTouchOutset: CGFloat = (TextActionButton.touchHeight - headerHeight) / 2
    }

    let actionButton: TextActionButton

    private let headerView = TouchOutsetView(verticalOutset: Layout.headerTouchOutset)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 14)
        label.textColor = .gray4
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 14)
        label.textColor = .gray5
        label.isHidden = true
        return label
    }()

    private let contentContainer = UIView()

    init(title: String, actionTitle: String? = nil) {
        self.actionButton = TextActionButton(title: actionTitle ?? "")
        super.init(frame: .zero)
        titleLabel.text = title
        actionButton.isHidden = actionTitle == nil
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        headerView.addSubViews([titleLabel, countLabel, actionButton])
        addSubViews([headerView, contentContainer])

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.headerHeight)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        countLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(6)
            $0.centerY.equalToSuperview()
        }

        actionButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.height.equalTo(TextActionButton.touchHeight)
            $0.leading.greaterThanOrEqualTo(countLabel.snp.trailing).offset(12)
        }

        contentContainer.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(Layout.contentSpacing)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 헤더 위로 넓힌 터치 영역까지 받는다
        return bounds.inset(by: UIEdgeInsets(top: -Layout.headerTouchOutset, left: 0, bottom: 0, right: 0)).contains(point)
    }

    func setContent(_ view: UIView) {
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        contentContainer.addSubview(view)
        view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    /// "단계 1/2"의 숫자. nil 이면 숨긴다
    func setCount(_ count: String?) {
        countLabel.text = count
        countLabel.isHidden = count == nil
        accessibilityLabel = [titleLabel.text, count].compactMap { $0 }.joined(separator: " ")
    }

    func setActionHidden(_ isHidden: Bool) {
        actionButton.isHidden = isHidden
    }
}

/// 메모 본문 (GH-59 R-5). `doc-body` Regular 16/28, 선택·복사만 되고 편집은 안 된다.
final class DocumentBodyView: UITextView {
    init() {
        super.init(frame: .zero, textContainer: nil)
        isEditable = false
        isSelectable = true
        isScrollEnabled = false
        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        dataDetectorTypes = []
        // 선택 손잡이·커서만 파랗게 보이지 않게 글자색과 맞춘다 (R-7)
        tintColor = .gray4
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        attributedText = SeepTextStyle.docBody.attributedString(text ?? "", color: .gray5)
    }
}

/// 위아래로 터치 영역을 넓힌 뷰. 얇은 줄 안의 44pt 버튼이 줄 밖까지 눌리게 한다.
final class TouchOutsetView: UIView {
    private let verticalOutset: CGFloat

    init(verticalOutset: CGFloat) {
        self.verticalOutset = verticalOutset
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: 0, dy: -verticalOutset).contains(point)
    }
}

/// 작성·수정과 상세가 같이 쓰는 섹션 뷰(단계·모으기·장소·사진)의 모양 (GH-59).
/// `.form`(기본)은 작성·수정 화면 그대로, `.document`는 상세 문서용 — 자체 헤더·회색 상자를 숨기고 `DocumentSectionView` 안에 들어간다.
enum WishSectionStyle {
    case form
    case document
}
