import UIKit

final class HomeWishCollectionViewCell: BaseCollectionViewCell {
    static let registerId = "\(HomeWishCollectionViewCell.self)"
    static let size = CGSize(
        width: (UIScreen.main.bounds.width - 40 - 15) / 2,
        height: ((UIScreen.main.bounds.width - 40 - 15) / 2) * 1.09
    )
    
    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
    }
    
    private let emojiLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 36)
    }
    
    private let titleLabel = UILabel().then {
        $0.textColor = .gray5
        $0.numberOfLines = 2
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
            make.edges.equalTo(0)
        }
        
        self.emojiLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(16)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.right.equalToSuperview().offset(-14)
            make.top.equalTo(self.emojiLabel.snp.bottom).offset(12)
        }
        
        self.checkButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    func bind(wish: Wish) {
        self.emojiLabel.text = wish.emoji
        self.titleLabel.text = wish.title
        
        if let endDate = wish.endDate {
            self.ddayLabel.bind(dday: endDate)
        }
        
        self.tagLabel.isHidden = wish.hashtags.isEmpty
        if wish.hashtags.isEmpty {
            self.ddayLabel.snp.removeConstraints()
            self.ddayLabel.snp.makeConstraints { make in
                make.left.equalTo(self.titleLabel)
                make.bottom.equalTo(self.checkButton)
            }
        } else {
            self.tagLabel.text = wish.hashtags[0]
            
            self.ddayLabel.snp.removeConstraints()
            self.tagLabel.snp.removeConstraints()
            self.ddayLabel.snp.makeConstraints { make in
                make.left.equalTo(self.titleLabel)
                make.bottom.equalTo(self.tagLabel.snp.top).offset(-6)
            }
            
            self.tagLabel.snp.makeConstraints { make in
                make.left.height.equalTo(self.ddayLabel)
                make.bottom.equalTo(self.checkButton)
            }
        }
    }
}
