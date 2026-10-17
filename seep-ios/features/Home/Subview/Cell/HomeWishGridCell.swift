import UIKit

import CombineCocoa

final class HomeWishGridCell: BaseCollectionViewCell {
    enum Layout {
        static let spacing: CGFloat = 15
        static let heightRatio: CGFloat = 1.09
        /// 한 열에 이 폭이 확보될 때마다 열을 늘린다. 셀 폭이 아이폰(약 174pt)과 비슷하게 유지되는 값.
        /// 사용 가능 폭 540pt(컬렉션뷰 580pt)부터 3열 — 아이폰·듀오 바깥은 2열, 듀오 안쪽(폭 600 제한 시 560)은 3열
        static let columnWidthUnit: CGFloat = 180
        static let minimumColumnCount = 2

        /// availableWidth: 섹션 좌우 inset을 뺀 폭
        static func columnCount(availableWidth: CGFloat) -> Int {
            guard availableWidth > 0 else { return minimumColumnCount }
            return max(minimumColumnCount, Int(availableWidth / columnWidthUnit))
        }

        static func itemSize(availableWidth: CGFloat) -> CGSize {
            let columnCount = CGFloat(columnCount(availableWidth: availableWidth))
            let width = max(0, (availableWidth - spacing * (columnCount - 1)) / columnCount)
            return CGSize(width: width, height: width * heightRatio)
        }
    }
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
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
        label.numberOfLines = 2
        label.font = .appleSemiBold(size: 16)
        return label
    }()
    
    private let ddayLabel = DdayLabel()
    
    private let tagLabel = TagLabel()
    
    private let stepProgressBar = StepProgressBar(width: 32)
    
    private let stepProgressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray4
        label.font = .appleBold(size: 11)
        return label
    }()
    
    private let finishButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icCheckOff.image.resizeImage(scaledTo: 30), for: .normal)
        button.setImage(Assets.Icons.icCheckOn.image.resizeImage(scaledTo: 30), for: .selected)
        return button
    }()
    
    override func setup() {
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.attributedText = nil
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(containerView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ddayLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(stepProgressBar)
        contentView.addSubview(stepProgressLabel)
        contentView.addSubview(finishButton)
        
        containerView.snp.makeConstraints {
            $0.edges.equalTo(0)
        }
        
        emojiLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.top.equalToSuperview().offset(14)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.trailing.equalToSuperview().offset(-14)
            $0.top.equalTo(emojiLabel.snp.bottom).offset(4)
        }
        
        finishButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.bottom.equalToSuperview().offset(-14)
            $0.size.equalTo(30)
        }
        
        // 그리드는 뱃지가 세로로 쌓이므로, 오른쪽이 비어 있는 D-day 줄에 진행도를 붙인다
        stepProgressBar.snp.makeConstraints {
            $0.leading.equalTo(ddayLabel.snp.trailing).offset(6)
            $0.centerY.equalTo(ddayLabel)
        }
        
        stepProgressLabel.snp.makeConstraints {
            $0.leading.equalTo(stepProgressBar.snp.trailing).offset(4)
            $0.centerY.equalTo(ddayLabel)
        }
    }
    
    func bind(viewModel: HomeWishCellViewModel) {
        setupWish(viewModel.output.wish)
        setupStepProgress(viewModel.output.stepProgress)
        
        finishButton.tapPublisher
            .subscribe(viewModel.input.didTapFinish)
            .store(in: &cancellables)
    }
    
    func setupWish(_ wish: Wish) {
        emojiLabel.text = wish.emoji
        titleLabel.text = wish.title
        ddayLabel.bind(dday: wish.endDate)
        finishButton.isSelected = wish.isSuccess
        
        tagLabel.isHidden = wish.hashtag.isEmpty
        if wish.hashtag.isEmpty {
            ddayLabel.snp.removeConstraints()
            ddayLabel.snp.makeConstraints {
                $0.left.equalTo(titleLabel)
                $0.bottom.equalTo(finishButton)
            }
        } else {
            tagLabel.text = HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag
            
            ddayLabel.snp.removeConstraints()
            tagLabel.snp.removeConstraints()
            ddayLabel.snp.makeConstraints {
                $0.leading.equalTo(titleLabel)
                $0.bottom.equalTo(tagLabel.snp.top).offset(-6)
            }
            
            tagLabel.snp.makeConstraints {
                $0.left.height.equalTo(ddayLabel)
                $0.bottom.equalTo(finishButton)
            }
        }
        
        if wish.isSuccess {
            emojiLabel.alpha = 0.5
            titleLabel.alpha = 0.5
            
            let attributedString = NSMutableAttributedString(string: wish.title)
            attributedString.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: UIColor.gray4.copy()
            ], range: NSRange(location: 0, length: wish.title.count))
            titleLabel.attributedText = attributedString
            
            ddayLabel.alpha = 0.5
            tagLabel.alpha = 0.5
        } else {
            emojiLabel.alpha = 1
            titleLabel.alpha = 1
            ddayLabel.alpha = 1
            tagLabel.alpha = 1
        }
    }
    
    private func setupStepProgress(_ progress: WishStepProgress?) {
        stepProgressBar.isHidden = progress == nil
        stepProgressLabel.isHidden = progress == nil
        guard let progress else { return }
        
        stepProgressBar.bind(progress: progress)
        stepProgressLabel.text = Strings.Home.stepProgressFormat(progress.doneCount, progress.totalCount)
    }
}
