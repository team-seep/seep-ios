import UIKit

import SnapKit

/// 회고 카드 한 장 (GH-34 R-4). 이 뷰만 이미지로 그려 공유한다 (R-5).
final class YearReviewCardView: BaseView {
    private enum Layout {
        static let inset: CGFloat = 20
    }

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: Assets.Icons.icLogoBlack.image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let yearLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 12)
        label.textColor = .gray4
        return label
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let categoryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    private let categoryViews: [Category: YearReviewCategoryView] = [
        .wantToDo: YearReviewCategoryView(category: .wantToDo),
        .wantToGet: YearReviewCategoryView(category: .wantToGet),
        .wantToGo: YearReviewCategoryView(category: .wantToGo)
    ]

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        return view
    }()

    /// 숨길 수 있는 아래 영역. 숨기면 간격도 같이 접힌다
    private let detailStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 16
        return stackView
    }()

    private let longestHeldView = YearReviewLongestHeldView()
    private let busiestMonthView = YearReviewBusiestMonthView()
    private let noteOfYearView = YearReviewNoteView()

    override func setup() {
        backgroundColor = .gray1
        layer.cornerRadius = 12
        clipsToBounds = true

        [Category.wantToDo, .wantToGet, .wantToGo].compactMap { categoryViews[$0] }.forEach {
            categoryStackView.addArrangedSubview($0)
        }
        detailStackView.addArrangedSubview(longestHeldView)
        detailStackView.addArrangedSubview(busiestMonthView)
        detailStackView.addArrangedSubview(noteOfYearView)
        addSubViews([logoImageView, yearLabel, headlineLabel, categoryStackView, dividerView, detailStackView])
    }

    override func bindConstraints() {
        logoImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.inset)
            $0.top.equalToSuperview().offset(22)
            $0.height.equalTo(18)
            let logoSize = Assets.Icons.icLogoBlack.image.size
            if logoSize.height > 0 {
                $0.width.equalTo(logoImageView.snp.height).multipliedBy(logoSize.width / logoSize.height)
            }
        }

        yearLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Layout.inset)
            $0.centerY.equalTo(logoImageView)
        }

        headlineLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.inset)
            $0.top.equalTo(logoImageView.snp.bottom).offset(18)
        }

        categoryStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.inset)
            $0.top.equalTo(headlineLabel.snp.bottom).offset(20)
        }

        dividerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.inset)
            $0.top.equalTo(categoryStackView.snp.bottom).offset(20)
            $0.height.equalTo(1)
        }

        detailStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.inset)
            $0.top.equalTo(dividerView.snp.bottom).offset(18)
            $0.bottom.equalToSuperview().offset(-Layout.inset)
        }
    }

    func bind(summary: YearReviewSummary) {
        yearLabel.text = "\(summary.year)"
        headlineLabel.attributedText = makeHeadline(count: summary.totalCount)
        categoryViews.forEach { category, view in
            view.bind(count: summary.count(of: category))
        }

        if let longestHeld = summary.longestHeld {
            longestHeldView.bind(wish: longestHeld.wish, days: longestHeld.days)
        }
        longestHeldView.isHidden = summary.longestHeld == nil

        if let busiestMonth = summary.busiestMonth {
            busiestMonthView.bind(month: busiestMonth.month, count: busiestMonth.count)
        }
        busiestMonthView.isHidden = summary.busiestMonth == nil

        if let noteOfYear = summary.noteOfYear {
            noteOfYearView.bind(wish: noteOfYear)
        }
        noteOfYearView.isHidden = summary.noteOfYear == nil
    }

    private func makeHeadline(count: Int) -> NSAttributedString {
        let text = Strings.YearReview.headlineFormat(count)
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
            range: nsText.range(of: Strings.YearReview.headlineBoldFormat(count))
        )
        attributedText.addAttribute(
            .foregroundColor,
            value: UIColor.tennisGreen,
            range: nsText.range(of: Strings.YearReview.countFormat(count))
        )
        return attributedText
    }
}

/// 카테고리 한 칸: 일러스트 + 이름 + 완료 수
private final class YearReviewCategoryView: BaseView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 16)
        label.textColor = .gray5
        return label
    }()

    init(category: Category) {
        super.init(frame: .zero)
        switch category {
        case .wantToDo:
            imageView.image = Assets.Images.imgCategoryWantToDo.image
            nameLabel.text = Strings.commonCategoryWantToDo
        case .wantToGet:
            imageView.image = Assets.Images.imgCategoryWantToGet.image
            nameLabel.text = Strings.commonCategoryWantToGet
        case .wantToGo:
            imageView.image = Assets.Images.imgCategoryWantToGo.image
            nameLabel.text = Strings.commonCategoryWantToGo
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        backgroundColor = .gray2
        layer.cornerRadius = 12
        addSubViews([imageView, nameLabel, countLabel])
    }

    override func bindConstraints() {
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(44)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom)
            $0.centerX.equalToSuperview()
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    func bind(count: Int) {
        countLabel.text = Strings.YearReview.countFormat(count)
    }
}

/// 가장 오래 품고 이룬 싶
private final class YearReviewLongestHeldView: BaseView {
    private let captionLabel = YearReviewCaptionLabel(text: Strings.YearReview.LongestHeld.title)

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

    private let daysLabel = UILabel()

    override func setup() {
        addSubViews([captionLabel, emojiLabel, titleLabel, daysLabel])
    }

    override func bindConstraints() {
        captionLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }

        emojiLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalTo(captionLabel.snp.bottom).offset(8)
            $0.size.equalTo(40)
            $0.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualToSuperview()
            $0.bottom.equalTo(emojiLabel.snp.centerY)
        }

        daysLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.equalTo(emojiLabel.snp.centerY)
        }
    }

    func bind(wish: Wish, days: Int) {
        emojiLabel.text = wish.emoji
        titleLabel.text = wish.title

        let text = Strings.YearReview.LongestHeld.daysFormat(days)
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.appleRegular(size: 14) as Any,
            .foregroundColor: UIColor.gray4
        ])
        attributedText.addAttributes([
            .font: UIFont.appleBold(size: 14) as Any,
            .foregroundColor: UIColor.gray5
        ], range: (text as NSString).range(of: Strings.YearReview.LongestHeld.daysBoldFormat(days)))
        daysLabel.attributedText = attributedText
    }
}

/// 가장 많이 이룬 달
private final class YearReviewBusiestMonthView: BaseView {
    private let captionLabel = YearReviewCaptionLabel(text: Strings.YearReview.BusiestMonth.title)

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 16)
        label.textColor = .gray5
        return label
    }()

    override func setup() {
        addSubViews([captionLabel, valueLabel])
    }

    override func bindConstraints() {
        captionLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }

        valueLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.equalTo(captionLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview()
        }
    }

    func bind(month: Int, count: Int) {
        valueLabel.text = Strings.YearReview.BusiestMonth.format(month, count)
    }
}

/// 올해의 한 줄 (소감)
private final class YearReviewNoteView: BaseView {
    private let captionLabel = YearReviewCaptionLabel(text: Strings.YearReview.NoteOfYear.title)

    private let noteLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 14)
        label.textColor = .gray5
        label.numberOfLines = 0
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override func setup() {
        backgroundColor = .gray2
        layer.cornerRadius = 12
        addSubViews([captionLabel, noteLabel, titleLabel])
    }

    override func bindConstraints() {
        captionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(14)
        }

        noteLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.top.equalTo(captionLabel.snp.bottom).offset(4)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.top.equalTo(noteLabel.snp.bottom).offset(2)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    func bind(wish: Wish) {
        noteLabel.text = Strings.Home.FinishNote.cellFormat(wish.finishNote)
        titleLabel.text = wish.title
    }
}

private final class YearReviewCaptionLabel: UILabel {
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = .appleMedium(size: 12)
        textColor = .gray4
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
