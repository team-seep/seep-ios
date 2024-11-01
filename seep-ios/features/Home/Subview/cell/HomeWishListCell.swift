import UIKit

final class HomeWishListCell: BaseCollectionViewCell {
    enum Layout {
        static let size = CGSize(width: UIUtils.windowBounds.width - 40, height: 70)
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
    
    private let checkButton: UIButton = {
        let button = UIButton()
        button.setImage(.icCheckOff, for: .normal)
        button.setImage(.icCheckOn, for: .highlighted)
        return button
    }()
    
    override func setup() {
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(containerView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ddayLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(checkButton)
        
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
        
        checkButton.snp.makeConstraints {
            $0.centerY.equalTo(containerView)
            $0.trailing.equalTo(containerView).offset(-16)
        }
    }
    
    func bind(viewModel: HomeWishCellViewModel) {
        setupWish(viewModel.output.wish)
    }
  
    private func setupWish(_ wish: Wish) {
        emojiLabel.text = wish.emoji
        titleLabel.text = wish.title
        ddayLabel.bind(dday: wish.endDate)
        tagLabel.text = HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag
        tagLabel.isHidden = wish.hashtag.isEmpty
    }
}
