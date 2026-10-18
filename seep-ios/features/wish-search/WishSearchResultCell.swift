import UIKit

/// 검색 결과 셀. 홈 리스트 셀(`HomeWishListCell`)과 같은 모양이고, 일치 글자를 강조한다 (GH-32 R-6, R-7).
final class WishSearchResultCell: BaseCollectionViewCell {
    enum Layout {
        static let height: CGFloat = HomeWishListCell.Layout.height
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray1
        view.layer.cornerRadius = 12
        return view
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36)
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray5
        label.font = .appleSemiBold(size: 16)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let ddayLabel = DdayLabel()

    private let tagLabel = TagLabel()

    private let memoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray4
        label.font = .appleMedium(size: 12)
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()

    /// 완료 여부 표시만 한다. 검색 화면에서는 체크할 수 없다 (R-7)
    private let finishImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()

    override func setup() {
        backgroundColor = .clear
        contentView.addSubview(containerView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ddayLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(memoLabel)
        contentView.addSubview(finishImageView)
    }

    override func bindConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(Layout.height)
        }

        emojiLabel.snp.makeConstraints {
            $0.leading.equalTo(containerView).offset(14)
            $0.centerY.equalToSuperview()
        }

        finishImageView.snp.makeConstraints {
            $0.centerY.equalTo(containerView)
            $0.trailing.equalTo(containerView).offset(-16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(emojiLabel).offset(3)
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(14)
            $0.trailing.lessThanOrEqualTo(finishImageView.snp.leading).offset(-12)
        }

        ddayLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
        }

        tagLabel.snp.makeConstraints {
            $0.leading.equalTo(ddayLabel.snp.trailing).offset(7)
            $0.centerY.height.equalTo(ddayLabel)
        }

        // 뱃지 줄 자리에 한 줄로 둔다. 체크 원 앞에서 말줄임해 셀 높이를 유지한다
        memoLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(finishImageView.snp.leading).offset(-12)
            $0.centerY.equalTo(ddayLabel)
        }
        memoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        emojiLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.attributedText = nil
        memoLabel.attributedText = nil
    }

    func bind(item: WishSearchResultItem) {
        let wish = item.wish
        emojiLabel.text = wish.emoji
        titleLabel.attributedText = makeTitle(wish: wish, highlightRange: item.titleHighlightRange)
        ddayLabel.bind(dday: wish.endDate)
        tagLabel.text = HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag
        finishImageView.image = wish.isSuccess ? Assets.Icons.icCheckOn.image : Assets.Icons.icCheckOff.image

        let alpha: CGFloat = wish.isSuccess ? 0.5 : 1
        emojiLabel.alpha = alpha
        titleLabel.alpha = alpha
        ddayLabel.alpha = alpha
        tagLabel.alpha = alpha
        memoLabel.alpha = alpha

        if let memoSnippet = item.memoSnippet {
            memoLabel.isHidden = false
            memoLabel.attributedText = makeMemo(snippet: memoSnippet)
            ddayLabel.isHidden = true
            tagLabel.isHidden = true
        } else {
            memoLabel.isHidden = true
            ddayLabel.isHidden = false
            tagLabel.isHidden = wish.hashtag.isEmpty
        }
    }

    private func makeTitle(wish: Wish, highlightRange: NSRange?) -> NSAttributedString {
        let title = NSMutableAttributedString(string: wish.title, attributes: [
            .font: UIFont.appleSemiBold(size: 16) as Any,
            .foregroundColor: UIColor.gray5
        ])
        if let highlightRange {
            title.addAttribute(.foregroundColor, value: UIColor.seepBlue, range: highlightRange)
        }
        if wish.isSuccess {
            // 홈과 같이 완료 위시는 취소선
            title.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: UIColor.gray4
            ], range: NSRange(location: 0, length: title.length))
        }
        return title
    }

    private func makeMemo(snippet: WishSearchMemoSnippet) -> NSAttributedString {
        let prefix = Strings.WishSearch.memoFormat("")
        let memo = NSMutableAttributedString(string: Strings.WishSearch.memoFormat(snippet.text), attributes: [
            .font: UIFont.appleMedium(size: 12) as Any,
            .foregroundColor: UIColor.gray4
        ])
        let offset = (prefix as NSString).length
        let highlight = NSRange(location: snippet.highlightRange.location + offset, length: snippet.highlightRange.length)
        if NSMaxRange(highlight) <= memo.length {
            memo.addAttribute(.foregroundColor, value: UIColor.seepBlue, range: highlight)
        }
        return memo
    }
}
