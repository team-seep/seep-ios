import UIKit

import SnapKit

/// 위시 단계 진행 바. 트랙 `gray2_5` 위에 완료 비율만큼 `tennisGreen` 을 채운다.
final class StepProgressBar: UIView {
    private let barWidth: CGFloat

    private let fillView: UIView = {
        let view = UIView()
        view.backgroundColor = .tennisGreen
        view.layer.cornerRadius = 2
        return view
    }()

    init(width: CGFloat) {
        self.barWidth = width
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: barWidth, height: 4)
    }

    func bind(progress: WishStepProgress?) {
        let ratio = progress?.ratio ?? 0
        fillView.snp.remakeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(barWidth * CGFloat(ratio))
        }
    }

    private func setup() {
        backgroundColor = .gray2_5
        layer.cornerRadius = 2
        clipsToBounds = true
        addSubview(fillView)
        // 크기는 intrinsicContentSize 로 정한다 — 셀이 위치 제약을 remake 해도 크기가 유지되도록
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        bind(progress: nil)
    }
}
