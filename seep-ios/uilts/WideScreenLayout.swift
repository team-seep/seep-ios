import UIKit

import SnapKit

/// 넓은 화면(듀오 안쪽 951pt 등) 레이아웃 규칙 (GH-12).
/// 화면 폭이 `maxContentWidth` 이하면(아이폰 전 기종) 지금처럼 화면 전체를 쓰고,
/// 넘으면 콘텐츠를 `maxContentWidth` 기둥으로 가운데 둔다. 기둥 안 좌우 여백(20pt)은 각 화면 그대로.
enum WideScreenLayout {
    /// 콘텐츠 기둥 최대 폭
    static let maxContentWidth: CGFloat = 600

    /// 카테고리 탭 줄 최대 폭. 가장 넓은 아이폰(Pro Max 440pt) 탭 줄 폭(440 - 40)에 맞춰
    /// 아이폰에서는 그대로 두고, 그보다 넓으면 탭 간격이 더 벌어지지 않게 한다.
    static let maxCategoryTabWidth: CGFloat = 400

    static func contentWidth(containerWidth: CGFloat) -> CGFloat {
        return min(max(containerWidth, 0), maxContentWidth)
    }

    static func horizontalInset(containerWidth: CGFloat) -> CGFloat {
        return max(0, (containerWidth - maxContentWidth) / 2)
    }

    /// superview 가운데에 최대 폭 기둥으로 둔다. 폭이 좁으면 superview 폭 그대로다.
    static func makeColumnConstraints(_ make: ConstraintMaker) {
        make.centerX.equalToSuperview()
        make.width.lessThanOrEqualTo(maxContentWidth)
        make.width.equalToSuperview().priority(.high)
    }
}

/// 화면 루트 뷰를 감싸 넓은 화면에서 최대 폭 기둥으로 가운데 둔다.
/// 기존 화면 뷰의 제약을 건드리지 않으려고 VC `loadView`에서 한 번 감싼다.
final class WideScreenContainerView: UIView {
    let contentView: UIView

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        backgroundColor = contentView.backgroundColor
        addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            WideScreenLayout.makeColumnConstraints($0)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
