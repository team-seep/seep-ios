import UIKit

class FinishedCollectionCell: BaseCollectionViewCell {
  
  static let registerId = "\(FinishedCollectionCell.self)"
  
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
  
  let finishDateLabel = UILabel().then {
    $0.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 11)
    $0.textColor = .black
    $0.alpha = 0.4
  }
  
  let tagLabel = PaddingLabel(
    topInset: 2,
    bottomInset: 2,
    leftInset: 6,
    rightInset: 6
  ).then {
    $0.textColor = UIColor(r: 153, g: 153, b: 153)
    $0.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 11)
    $0.backgroundColor = UIColor(r: 241, g: 241, b: 241)
    $0.layer.cornerRadius = 4
    $0.layer.masksToBounds = true
  }
  
  let checkedImage = UIImageView().then {
    $0.image = UIImage(named: "img_check_on")
  }
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.addSubViews(
      containerView, emojiLabel, titleLabel, finishDateLabel,
      tagLabel, checkedImage
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
    
    self.finishDateLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(17)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(12)
    }
    
    self.tagLabel.snp.makeConstraints { make in
      make.left.equalTo(self.finishDateLabel)
      make.top.equalTo(self.finishDateLabel.snp.bottom).offset(6)
    }
    
    self.checkedImage.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-14)
      make.bottom.equalToSuperview().offset(-20)
    }
  }
  
  func bind(wish: Wish) {
    self.emojiLabel.text = wish.emoji
    self.titleLabel.text = wish.title
    self.finishDateLabel.text = DateUtils.toString(format: "yyyy년 MM월 dd일", date: wish.finishDate!)
    self.tagLabel.text = wish.hashtag
    self.tagLabel.isHidden = wish.hashtag.isEmpty
  }
}
