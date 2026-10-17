import UIKit

import CombineCocoa

final class HomeWishListCell: BaseCollectionViewCell {
    enum Layout {
        static let height: CGFloat = 70
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
        button.setImage(Assets.Icons.icCheckOff.image, for: .normal)
        button.setImage(Assets.Icons.icCheckOn.image, for: .selected)
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
            $0.edges.equalToSuperview()
            $0.height.equalTo(Layout.height)
        }
        
        emojiLabel.snp.makeConstraints {
            $0.leading.equalTo(containerView).offset(14)
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(emojiLabel).offset(3)
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(14)
        }
        
        ddayLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
        
        tagLabel.snp.makeConstraints {
            $0.leading.equalTo(ddayLabel.snp.trailing).offset(7)
            $0.centerY.height.equalTo(ddayLabel)
        }
        
        finishButton.snp.makeConstraints {
            $0.centerY.equalTo(containerView)
            $0.trailing.equalTo(containerView).offset(-16)
        }
        
        stepProgressBar.snp.makeConstraints {
            $0.leading.equalTo(tagLabel.snp.trailing).offset(9)
            $0.centerY.equalTo(ddayLabel)
        }
        
        stepProgressLabel.snp.makeConstraints {
            $0.leading.equalTo(stepProgressBar.snp.trailing).offset(4)
            $0.centerY.equalTo(ddayLabel)
        }
    }
    
    func bind(viewModel: HomeWishCellViewModel) {
        setupWish(viewModel.output.wish)
        setupStepProgress(viewModel.output.stepProgress, isTagHidden: viewModel.output.wish.hashtag.isEmpty)
        
        finishButton.tapPublisher
            .subscribe(viewModel.input.didTapFinish)
            .store(in: &cancellables)
    }
  
    private func setupWish(_ wish: Wish) {
        emojiLabel.text = wish.emoji
        titleLabel.text = wish.title
        ddayLabel.bind(dday: wish.endDate)
        tagLabel.text = HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag
        tagLabel.isHidden = wish.hashtag.isEmpty
        finishButton.isSelected = wish.isSuccess
        
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
    
    private func setupStepProgress(_ progress: WishStepProgress?, isTagHidden: Bool) {
        stepProgressBar.isHidden = progress == nil
        stepProgressLabel.isHidden = progress == nil
        guard let progress else { return }
        
        stepProgressBar.bind(progress: progress)
        stepProgressLabel.text = Strings.Home.stepProgressFormat(progress.doneCount, progress.totalCount)
        stepProgressBar.snp.remakeConstraints {
            $0.leading.equalTo(isTagHidden ? ddayLabel.snp.trailing : tagLabel.snp.trailing).offset(9)
            $0.centerY.equalTo(ddayLabel)
        }
    }
}
