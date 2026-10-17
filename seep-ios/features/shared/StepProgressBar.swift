import UIKit

import SnapKit

/// 위시 진행 바. 트랙 `gray2_5` 위에 비율만큼 `tennisGreen` 을 채운다.
/// 단계 진행도(GH-5)와 모은 돈 진행도(GH-16)가 같이 쓴다.
final class StepProgressBar: UIView {
    /// nil 이면 폭은 바깥 제약으로 정한다 (모으기 상자 안 전체 폭 바)
    private let barWidth: CGFloat?
    private let barHeight: CGFloat
    private var ratio: CGFloat = 0

    private let fillView: UIView = {
        let view = UIView()
        view.backgroundColor = .tennisGreen
        return view
    }()

    init(width: CGFloat? = nil, height: CGFloat = 4) {
        self.barWidth = width
        self.barHeight = height
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: barWidth ?? UIView.noIntrinsicMetric, height: barHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fillView.frame = CGRect(x: 0, y: 0, width: bounds.width * ratio, height: bounds.height)
    }

    func bind(progress: WishStepProgress?) {
        bind(ratio: progress?.ratio ?? 0)
    }

    /// 0...1 밖의 값은 잘라낸다.
    func bind(ratio: Double) {
        self.ratio = CGFloat(min(max(ratio, 0), 1))
        setNeedsLayout()
    }

    private func setup() {
        backgroundColor = .gray2_5
        layer.cornerRadius = barHeight / 2
        fillView.layer.cornerRadius = barHeight / 2
        clipsToBounds = true
        addSubview(fillView)
        // 크기는 intrinsicContentSize 로 정한다 — 셀이 위치 제약을 remake 해도 크기가 유지되도록
        if barWidth != nil {
            setContentHuggingPriority(.required, for: .horizontal)
        }
        setContentHuggingPriority(.required, for: .vertical)
    }
}
