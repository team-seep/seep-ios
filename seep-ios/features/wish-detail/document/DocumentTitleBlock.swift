import UIKit

import SnapKit

/// 상세 문서 머리: 이모지 → 제목(`doc-title`, 최대 2줄) → D-day 줄 → 메타 줄 (GH-59 R-2~R-4).
/// 보기 전용이라 파란 글자·화살표·입력 테두리가 없고 탭 반응도 없다 (R-7).
final class DocumentTitleBlock: UIView {
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 44)
        return label
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.accessibilityTraits = .header
        return label
    }()

    private let ddayLineView = DocDdayLineView()

    private let metaLineView = MetaLineView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubViews([emojiLabel, titleLabel, ddayLineView, metaLineView])

        emojiLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.height.equalTo(52)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(emojiLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
        }

        ddayLineView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview()
        }

        metaLineView.snp.makeConstraints {
            $0.top.equalTo(ddayLineView.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    func bind(summary: WishDetailSummary) {
        emojiLabel.text = summary.emoji
        emojiLabel.isHidden = summary.emoji.isEmpty
        titleLabel.attributedText = SeepTextStyle.docTitle.attributedString(
            summary.title,
            color: .gray5,
            lineBreakMode: .byTruncatingTail
        )
        ddayLineView.bind(line: summary.ddayLine)
        metaLineView.bind(summary: summary)
    }
}

/// 제목 바로 아래 큰 D-day 줄 (GH-59 R-3). 숫자 ExtraBold 30/36(단어는 Bold 20/28) + 날짜 Medium 14 `gray4`, 기준선 맞춤. 바탕·테두리 없음.
final class DocDdayLineView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.spacing = 10
        return stackView
    }()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 14)
        label.textColor = .gray4
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        [numberLabel, dateLabel].forEach(stackView.addArrangedSubview)
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(line: WishDetailSummary.DdayLine) {
        let font: UIFont? = line.isWord ? .appleBold(size: 20) : .appleExtraBold(size: 30)
        let lineHeight: CGFloat = line.isWord ? 28 : 36
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: line.tone.textColor,
            .paragraphStyle: paragraphStyle
        ]
        if let font {
            attributes[.font] = font
            attributes[.baselineOffset] = (lineHeight - font.lineHeight) / 4
        }
        numberLabel.attributedText = NSAttributedString(string: line.text, attributes: attributes)
        dateLabel.text = line.dateText
        dateLabel.isHidden = line.dateText == nil
        accessibilityLabel = [line.text, line.dateText].compactMap { $0 }.joined(separator: ", ")
    }
}

/// D-day 줄 아래 메타 한 줄: 카테고리 · 🔔 알림 요약 · #해시태그 (GH-59 R-4). `gray4`, 탭 반응 없음.
final class MetaLineView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(summary: WishDetailSummary) {
        let font = UIFont.appleRegular(size: 14) ?? .systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.maximumLineHeight = 22
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.gray4,
            .paragraphStyle: paragraphStyle,
            .baselineOffset: (22 - font.lineHeight) / 4
        ]
        let text = NSMutableAttributedString()
        summary.metaItems.enumerated().forEach { index, item in
            if index > 0 {
                var dotAttributes = baseAttributes
                dotAttributes[.foregroundColor] = UIColor.gray3
                text.append(NSAttributedString(string: "  ·  ", attributes: dotAttributes))
            }
            switch item {
            case .category(let value), .hashtag(let value):
                text.append(NSAttributedString(string: value, attributes: baseAttributes))
            case .notification(let value):
                text.append(Self.bellAttachment(font: font))
                text.append(NSAttributedString(string: " " + value, attributes: baseAttributes))
            }
        }
        label.attributedText = text
        label.accessibilityLabel = summary.metaText
    }

    private static func bellAttachment(font: UIFont) -> NSAttributedString {
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        guard let image = UIImage(systemName: "bell", withConfiguration: configuration)?
            .withTintColor(.gray4, renderingMode: .alwaysOriginal) else {
            return NSAttributedString()
        }
        let attachment = NSTextAttachment(image: image)
        attachment.bounds = CGRect(
            x: 0,
            y: (font.capHeight - image.size.height) / 2,
            width: image.size.width,
            height: image.size.height
        )
        return NSAttributedString(attachment: attachment)
    }
}
