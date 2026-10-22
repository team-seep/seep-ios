import UIKit
import Combine

import SnapKit

/// 위시 상세의 "모으기" 섹션 (GH-16 R-3). 헤더(아이콘·라벨·작은 진행 바·퍼센트) + 금액 상자(모은/목표·진행 바·문구·기록 목록) + "모은 돈 기록" 버튼.
/// 접히면 높이 0 이 되도록 위쪽 간격(26)까지 이 뷰가 갖는다.
final class WishSavingsView: BaseView {
    private enum Layout {
        static let topSpacing: CGFloat = 26
        static let boxInset: CGFloat = 16
    }

    /// 기록 행 X 탭 — 기록 id
    let deleteSavingPublisher = PassthroughSubject<String, Never>()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private let spacerView = UIView()

    private var style: WishSectionStyle = .form

    private let headerView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "banknote")
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray5
        label.text = Strings.Detail.Saving.title
        return label
    }()

    private let headerProgressBar = StepProgressBar(width: 48)

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 13)
        label.textColor = .gray4
        return label
    }()

    private let boxView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 12
        return view
    }()

    private let boxStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    /// 상세 문서 모양에서는 4pt 바로 갈아끼운다 (GH-59 D2)
    private var progressBar = StepProgressBar(height: 8)

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        return view
    }()

    private let recordStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    let addButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Detail.Saving.add, for: .normal)
        button.setTitleColor(.seepBlue, for: .normal)
        button.setImage(Assets.Icons.icSmallPlus.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .seepBlue
        button.titleLabel?.font = .appleExtraBold(size: 14)
        button.semanticContentAttribute = .forceLeftToRight
        return button
    }()

    override func setup() {
        headerView.addSubViews([iconImageView, titleLabel, headerProgressBar, percentLabel])
        [amountLabel, progressBar, messageLabel, dividerView, recordStackView].forEach(boxStackView.addArrangedSubview)
        boxStackView.setCustomSpacing(10, after: amountLabel)
        boxStackView.setCustomSpacing(10, after: progressBar)
        boxStackView.setCustomSpacing(14, after: messageLabel)
        boxStackView.setCustomSpacing(6, after: dividerView)
        boxView.addSubview(boxStackView)

        [spacerView, headerView, boxView, addButton].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(10, after: headerView)
        stackView.setCustomSpacing(4, after: boxView)
        addSubview(stackView)
    }

    override func bindConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        spacerView.snp.makeConstraints {
            $0.height.equalTo(Layout.topSpacing)
        }

        headerView.snp.makeConstraints {
            $0.height.equalTo(20)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }

        percentLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        headerProgressBar.snp.makeConstraints {
            $0.trailing.equalTo(percentLabel.snp.leading).offset(-6)
            $0.centerY.equalToSuperview()
        }

        boxStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Layout.boxInset)
            $0.bottom.equalToSuperview().inset(10)
            $0.leading.trailing.equalToSuperview().inset(Layout.boxInset)
        }

        dividerView.snp.makeConstraints {
            $0.height.equalTo(1)
        }

        addButton.snp.makeConstraints {
            $0.height.equalTo(44)
        }
    }

    /// 갖고 싶어요 + 목표 금액이 없으면 접는다 (R-1, R-7). 상세 문서 모양에서는 자체 간격·헤더·기록 버튼을 계속 숨긴다
    func setCollapsed(_ isCollapsed: Bool) {
        let hiddenInStyle: [UIView] = style == .document ? [spacerView, headerView, addButton] : []
        stackView.arrangedSubviews.forEach { view in
            view.isHidden = isCollapsed || hiddenInStyle.contains { $0 === view }
        }
    }

    /// 상세 문서 모양 (GH-59 R-6): 헤더·회색 상자·"모은 돈 기록" 버튼 없이 큰 금액 / 목표 · 진행 바 · 문구 · 기록.
    /// 제목 "모은 돈"과 "＋ 기록" 액션은 `DocumentSectionView`가 그린다.
    func configure(style: WishSectionStyle) {
        self.style = style
        guard style == .document else { return }
        boxView.backgroundColor = .clear
        boxView.layer.cornerRadius = 0
        boxStackView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        let thinBar = StepProgressBar(height: 4)
        if let index = boxStackView.arrangedSubviews.firstIndex(of: progressBar) {
            progressBar.removeFromSuperview()
            boxStackView.insertArrangedSubview(thinBar, at: index)
            boxStackView.setCustomSpacing(8, after: thinBar)
        }
        progressBar = thinBar
        setCollapsed(boxView.isHidden)
    }

    func bind(progress: WishSavingProgress?) {
        guard let progress else { return }

        headerProgressBar.bind(ratio: progress.ratio)
        progressBar.bind(ratio: progress.ratio)
        percentLabel.text = Strings.Detail.Saving.percentFormat(progress.percent)

        let amountText = NSMutableAttributedString(
            string: Strings.Common.wonFormat(AmountFormatter.string(from: progress.savedAmount)),
            attributes: [
                .font: (style == .document ? UIFont.appleExtraBold(size: 22) : UIFont.appleBold(size: 22)) as Any,
                .foregroundColor: UIColor.gray5
            ]
        )
        amountText.append(NSAttributedString(
            string: " " + Strings.Detail.Saving.targetFormat(AmountFormatter.string(from: progress.targetAmount)),
            attributes: [.font: UIFont.appleRegular(size: 14) as Any, .foregroundColor: UIColor.gray4]
        ))
        amountLabel.attributedText = amountText
        amountLabel.accessibilityLabel = amountText.string

        messageLabel.attributedText = makeMessage(progress: progress)
    }

    func bind(savings: [WishSaving]) {
        recordStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        savings.forEach { saving in
            let rowView = SavingRecordRowView(saving: saving)
            rowView.onTapDelete = { [weak self] in
                self?.deleteSavingPublisher.send(saving.id)
            }
            recordStackView.addArrangedSubview(rowView)
        }
        dividerView.isHidden = savings.isEmpty
        recordStackView.isHidden = savings.isEmpty
    }

    private func makeMessage(progress: WishSavingProgress) -> NSAttributedString {
        if progress.isCompleted {
            return NSAttributedString(
                string: Strings.Detail.Saving.completed,
                attributes: [.font: UIFont.appleBold(size: 14) as Any, .foregroundColor: UIColor.seepBlue]
            )
        }

        let remainingText = Strings.Common.wonFormat(AmountFormatter.string(from: progress.remainingAmount))
        let message = Strings.Detail.Saving.remainingFormat(AmountFormatter.string(from: progress.remainingAmount))
        let attributedText = NSMutableAttributedString(
            string: message,
            attributes: [.font: UIFont.appleRegular(size: 14) as Any, .foregroundColor: UIColor.gray5]
        )
        let boldRange = (message as NSString).range(of: remainingText)
        attributedText.addAttributes(
            [.font: UIFont.appleBold(size: 14) as Any, .foregroundColor: UIColor.seepBlue],
            range: boldRange
        )
        return attributedText
    }
}

/// 기록 한 줄: 날짜(MM.dd) · +금액 · 삭제(X)
private final class SavingRecordRowView: UIView {
    var onTapDelete: (() -> Void)?

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        return label
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray5
        return label
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icClose.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray3
        button.accessibilityLabel = Strings.Detail.Saving.delete
        return button
    }()

    init(saving: WishSaving) {
        super.init(frame: .zero)
        setup()
        dateLabel.text = DateUtils.toString(format: "MM.dd", date: saving.createdAt)
        amountLabel.text = Strings.Detail.Saving.recordFormat(AmountFormatter.string(from: saving.amount))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubViews([dateLabel, amountLabel, deleteButton])
        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)

        snp.makeConstraints {
            $0.height.equalTo(36)
        }

        dateLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.width.equalTo(56)
        }

        deleteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        amountLabel.snp.makeConstraints {
            $0.leading.equalTo(dateLabel.snp.trailing)
            $0.trailing.lessThanOrEqualTo(deleteButton.snp.leading)
            $0.centerY.equalToSuperview()
        }
    }

    @objc private func didTapDelete() {
        onTapDelete?()
    }
}
