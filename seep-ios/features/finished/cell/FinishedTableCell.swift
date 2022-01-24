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
    $0.font = .appleSemiBold(size: 16)
  }
  
  let finishDateLabel = UILabel().then {
    $0.font = .appleSemiBold(size: 11)
    $0.textColor = .black
    $0.alpha = 0.4
  }
  
  let tagLabel = TagLabel()
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.selectionStyle = .none
    self.addSubViews(
      containerView, emojiLabel, titleLabel, finishDateLabel,
      tagLabel
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
      make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
      make.width.greaterThanOrEqualTo(83)
    }
    
    self.tagLabel.snp.makeConstraints { make in
      make.left.equalTo(self.finishDateLabel.snp.right).offset(8)
      make.centerY.equalTo(self.finishDateLabel)
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
