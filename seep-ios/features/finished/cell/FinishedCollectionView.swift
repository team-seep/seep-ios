import UIKit

class FinishedCollectionCell: BaseCollectionViewCell {
  
  static let registerId = "\(FinishedCollectionCell.self)"
  
  let containerView = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 12
  }
  
  let emojiLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 28)
  }
  
  let titleLabel = UILabel().then {
    $0.textColor = .gray5
    $0.numberOfLines = 2
    $0.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 16)
  }
  
  let finishDateLabel = UILabel().then {
    $0.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 11)
    $0.textColor = .black
    $0.alpha = 0.4
  }
  
  let tagLabel = TagLabel()
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.addSubViews(
      containerView, emojiLabel, titleLabel, finishDateLabel,
      tagLabel
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
      make.left.equalTo(self.emojiLabel)
      make.right.equalToSuperview().offset(-14)
      make.top.equalTo(self.emojiLabel.snp.bottom).offset(12)
    }
    
    self.finishDateLabel.snp.makeConstraints { make in
      make.left.equalTo(self.emojiLabel)
      make.bottom.equalTo(self.tagLabel.snp.top).offset(-6)
    }
    
    self.tagLabel.snp.makeConstraints { make in
      make.left.equalTo(self.emojiLabel)
      make.bottom.equalToSuperview().offset(-20)
    }
  }
  
  func bind(wish: Wish) {
    self.emojiLabel.text = wish.emoji
    self.titleLabel.text = wish.title
    self.finishDateLabel.text = DateUtils.toString(format: "yyyy년 MM월 dd일", date: wish.finishDate!)
    
    if !wish.hashtags.isEmpty {
        self.tagLabel.text = wish.hashtags[0]
    }
    self.tagLabel.isHidden = wish.hashtags.isEmpty
  }
}
