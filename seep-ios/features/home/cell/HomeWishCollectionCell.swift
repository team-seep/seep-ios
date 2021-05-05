import UIKit

class HomeWishCollectionCell: BaseCollectionViewCell {
  
  static let registerId = "\(HomeWishCollectionCell.self)"
  
  let containerView = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 12
  }
  
  let emojiLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 36)
  }
  
  let titleLabel = UILabel().then {
    $0.textColor = .gray5
    $0.numberOfLines = 2
    $0.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 16)
  }
  
  let ddayLabel = DdayLabel()
  
  let tagLabel = TagLabel()
  
  let checkButton = UIButton().then {
    $0.setImage(.icCheckOff, for: .normal)
  }
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.addSubViews(
      containerView, emojiLabel, titleLabel, ddayLabel,
      tagLabel, checkButton
    )
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
    
    self.ddayLabel.snp.makeConstraints { make in
      make.left.equalTo(self.titleLabel)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(3)
    }
    
    self.tagLabel.snp.makeConstraints { make in
      make.left.height.equalTo(self.ddayLabel)
      make.top.equalTo(self.ddayLabel.snp.bottom).offset(6)
    }
    
    self.checkButton.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-14)
      make.bottom.equalToSuperview().offset(-20)
    }
  }
  
  func bind(wish: Wish) {
    self.emojiLabel.text = wish.emoji
    self.titleLabel.text = wish.title
    self.ddayLabel.bind(dday: wish.date)
    self.tagLabel.text = wish.hashtag
    self.tagLabel.isHidden = wish.hashtag.isEmpty
  }
}
