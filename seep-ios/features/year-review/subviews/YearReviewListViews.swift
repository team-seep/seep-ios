import UIKit

import SnapKit

/// 목록 맨 위 헤드라인 "2026년에 이룬 싶 / 12개 모두 모아봤어요"
final class YearReviewListHeaderView: UICollectionReusableView {
    static let kind = "YearReviewListHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(22)
            $0.top.equalToSuperview().offset(4)
            $0.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(year: Int, count: Int) {
        let text = Strings.YearReview.List.headlineFormat(String(year), count)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 31
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.appleLight(size: 22) as Any,
            .foregroundColor: UIColor.gray5,
            .paragraphStyle: paragraphStyle
        ])
        let nsText = text as NSString
        attributedText.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: nsText.range(of: Strings.YearReview.List.headlineBoldFormat(count))
        )
        attributedText.addAttribute(
            .foregroundColor,
            value: UIColor.tennisGreen,
            range: nsText.range(of: Strings.YearReview.countFormat(count), options: .backwards)
        )
        titleLabel.attributedText = attributedText
    }
}

/// 달 헤더 "12월 ··· 2개"
final class YearReviewListMonthHeaderView: UICollectionReusableView {
    static let kind = "YearReviewListMonthHeaderView"

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 14)
        label.textColor = .gray5
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 14)
        label.textColor = .gray4
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(monthLabel)
        addSubview(countLabel)
        monthLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(2)
            $0.bottom.equalToSuperview().offset(-10)
        }
        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-2)
            $0.centerY.equalTo(monthLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(month: Int, count: Int) {
        monthLabel.text = Strings.YearReview.List.monthFormat(month)
        countLabel.text = Strings.YearReview.countFormat(count)
    }
}

/// 올해 이룬 싶 셀: 이모지·제목·(소감 또는 완료일)·완료 체크
final class YearReviewListCell: BaseCollectionViewCell {
    enum Layout {
        static let height: CGFloat = 70
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray1
        view.layer.cornerRadius = 12
        return view
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 16)
        label.textColor = .gray5
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let noteLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let dateLabel = TagLabel()

    private let checkImageView: UIImageView = {
        let imageView = UIImageView(image: Assets.Icons.icCheckOn.image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override func setup() {
        contentView.addSubview(containerView)
        containerView.addSubViews([emojiLabel, titleLabel, noteLabel, dateLabel, checkImageView])
    }

    override func bindConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        emojiLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }

        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(30)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(14)
            $0.trailing.lessThanOrEqualTo(checkImageView.snp.leading).offset(-12)
            $0.bottom.equalTo(containerView.snp.centerY).offset(1)
        }

        noteLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(checkImageView.snp.leading).offset(-12)
            $0.top.equalTo(containerView.snp.centerY).offset(3)
        }

        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(containerView.snp.centerY).offset(5)
        }
    }

    func bind(item: YearReviewListViewModel.Item) {
        emojiLabel.text = item.wish.emoji
        titleLabel.text = item.wish.title
        noteLabel.text = item.note
        noteLabel.isHidden = item.note == nil
        dateLabel.text = item.finishDateText
        dateLabel.isHidden = item.note != nil
    }
}
