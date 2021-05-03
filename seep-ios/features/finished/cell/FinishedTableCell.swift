import UIKit

class FinishedTableCell: BaseTableViewCell {
  
  static let registerId = "\(FinishedTableCell.self)"
  
  let containerView = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 12
  }
  
  let emojiLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 36)
  }
  
  let titleLabel = UILabel().then {
    $0.textColor = .gray5
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
    self.selectionStyle = .none
    self.addSubViews(
      containerView, emojiLabel, titleLabel, finishDateLabel,
      tagLabel, checkedImage
    )
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
    
    self.finishDateLabel.snp.makeConstraints { make in
      make.left.equalTo(self.titleLabel)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(3)
    }
    
    self.tagLabel.snp.makeConstraints { make in
      make.left.equalTo(self.finishDateLabel.snp.right).offset(7)
      make.centerY.equalTo(self.finishDateLabel)
    }
    
    self.checkedImage.snp.makeConstraints { make in
      make.centerY.equalTo(self.containerView)
      make.right.equalTo(self.containerView).offset(-16)
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
