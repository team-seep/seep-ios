import UIKit

import CombineCocoa

/// 홈 헤드라인 아래 "올해 돌아보기" 배너 (GH-34 R-1, R-2). 셀 탭은 회고 열기, X는 닫기.
final class HomeYearReviewBannerCell: BaseCollectionViewCell {
    enum Layout {
        static let height: CGFloat = 64
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray1
        view.layer.cornerRadius = 12
        return view
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 16)
        label.textColor = .gray5
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView(image: Assets.Icons.icRightArrow.image.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        return view
    }()

    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icClose.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray3
        button.accessibilityLabel = Strings.Home.YearReview.close
        return button
    }()

    override func setup() {
        contentView.addSubview(containerView)
        containerView.addSubViews([captionLabel, titleLabel, arrowImageView, dividerView, closeButton])
    }

    override func bindConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(Layout.height)
        }

        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-4)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        dividerView.snp.makeConstraints {
            $0.trailing.equalTo(closeButton.snp.leading).offset(-2)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(1)
            $0.height.equalTo(24)
        }

        arrowImageView.snp.makeConstraints {
            $0.trailing.equalTo(dividerView.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        captionLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(arrowImageView.snp.leading).offset(-12)
            $0.top.equalToSuperview().offset(12)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(captionLabel)
            $0.trailing.lessThanOrEqualTo(arrowImageView.snp.leading).offset(-12)
            $0.top.equalTo(captionLabel.snp.bottom).offset(2)
        }
    }

    func bind(year: Int, count: Int) {
        captionLabel.text = Strings.Home.YearReview.captionFormat(String(year))

        let text = Strings.Home.YearReview.titleFormat(count)
        let attributedText = NSMutableAttributedString(string: text)
        let countRange = (text as NSString).range(of: Strings.Home.YearReview.countFormat(count))
        attributedText.addAttributes([
            .foregroundColor: UIColor.seepBlue,
            .font: UIFont.appleExtraBold(size: 16) as Any
        ], range: countRange)
        titleLabel.attributedText = attributedText
    }
}
