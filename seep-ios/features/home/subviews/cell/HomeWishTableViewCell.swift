import UIKit

final class HomeWishTableViewCell: BaseTableViewCell {
    static let registerId = "\(HomeWishTableViewCell.self)"
    
    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
    }
    
    private let emojiLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 36)
    }
    
    private let titleLabel = UILabel().then {
        $0.textColor = .gray5
        $0.font = .appleSemiBold(size: 16)
    }
    
    private let ddayLabel = DdayLabel()
    
    private let tagLabel = TagLabel()
    
    let checkButton = UIButton().then {
        $0.setImage(.icCheckOff, for: .normal)
        $0.setImage(.icCheckOn, for: .highlighted)
    }
    
    override func setup() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.contentView.isUserInteractionEnabled = false
        self.addSubViews([
            self.containerView,
            self.emojiLabel,
            self.titleLabel,
            self.ddayLabel,
            self.tagLabel,
            self.checkButton
        ])
    }
  
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.bottom.equalTo(self.emojiLabel).offset(17)
        }
        
        self.emojiLabel.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(14)
            make.top.equalTo(self.containerView).offset(17)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.emojiLabel).offset(3)
            make.left.equalTo(self.emojiLabel.snp.right).offset(14)
        }
        
        self.ddayLabel.snp.makeConstraints { make in
            make.left.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(5)
        }
        
        self.tagLabel.snp.makeConstraints { make in
            make.left.equalTo(self.ddayLabel.snp.right).offset(7)
            make.centerY.height.equalTo(self.ddayLabel)
        }
        
        self.checkButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.containerView)
            make.right.equalTo(self.containerView).offset(-16)
        }
    }
  
    func bind(wish: Wish) {
        self.emojiLabel.text = wish.emoji
        self.titleLabel.text = wish.title
        
        if let endDate = wish.endDate {
            self.ddayLabel.bind(dday: endDate)
        }
        
        if !wish.hashtags.isEmpty {
            self.tagLabel.text = wish.hashtags[0]
        }
        self.tagLabel.isHidden = wish.hashtags.isEmpty
    }
}
