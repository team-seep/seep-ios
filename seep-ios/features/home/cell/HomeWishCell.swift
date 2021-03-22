import UIKit

class HomeWishCell: BaseTableViewCell {
  
  static let registerId = "\(HomeWishCell.self)"
  
  let containerView = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 12
  }
  
  let emojiLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 36)
    $0.text = "📷"
  }
  
  let titleLabel = UILabel().then {
    $0.text = "필름카메라 구매"
    $0.textColor = UIColor(r: 51, g: 51, b: 51)
    $0.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 16)
    $0.setKern(kern: -0.64)
  }
  
  let deadlineLabel = PaddingLabel(
    topInset: 3,
    bottomInset: 1,
    leftInset: 6,
    rightInset: 6
  ).then {
    $0.text = "D-4"
    $0.textColor = UIColor(r: 235, g: 82, b: 82)
    $0.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 12)
    $0.layer.cornerRadius = 4
    $0.backgroundColor = UIColor(r: 255, g: 240, b: 240)
  }
  
  let tagLabel = PaddingLabel(
    topInset: 2,
    bottomInset: 2,
    leftInset: 6,
    rightInset: 6
  ).then {
    $0.text = "버킷리스트"
    $0.textColor = UIColor(r: 153, g: 153, b: 153)
    $0.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 11)
    $0.backgroundColor = UIColor(r: 241, g: 241, b: 241)
    $0.layer.cornerRadius = 4
  }
  
  let checkButton = UIButton().then {
    $0.setImage(UIImage(named: "img_check_off"), for: .normal)
  }
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.selectionStyle = .none
    self.addSubViews(
      containerView, emojiLabel, titleLabel, deadlineLabel,
      tagLabel, checkButton
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
    
    self.deadlineLabel.snp.makeConstraints { make in
      make.left.equalTo(self.titleLabel)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(5)
    }
    
    self.tagLabel.snp.makeConstraints { make in
      make.left.equalTo(self.deadlineLabel.snp.right).offset(7)
      make.centerY.equalTo(self.deadlineLabel)
    }
    
    self.checkButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.containerView)
      make.right.equalTo(self.containerView).offset(-16)
    }
  }
  
  func bind(wish: Wish) {
    self.emojiLabel.text = wish.emoji
    self.titleLabel.text = wish.title
    self.deadlineLabel.text = self.calculateDDay(date: wish.date)
  }
  
  private func calculateDDay(date: Date) -> String {
    let dday = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? -1
    
    return "D-\(dday)"
  }
}
