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
    $0.font = .systemFont(ofSize: 16, weight: .bold)
  }
  
  let deadlineLabel = UILabel().then {
    let text = "하루 남았어요"
    let attributedString = NSMutableAttributedString(string: text)
    let boldTextRange = (text as NSString).range(of: "하루")
    
    attributedString.addAttribute(
      .font,
      value: UIFont.systemFont(ofSize: 12, weight: .bold),
      range: boldTextRange
    )
    $0.textColor = UIColor(r: 136, g: 136, b: 136)
    $0.font = .systemFont(ofSize: 12)
    $0.attributedText = attributedString
  }
  
  let tagButton = UIButton().then {
    $0.setTitle("버킷리스트", for: .normal)
    $0.setTitleColor(UIColor(r: 153, g: 153, b: 153), for: .normal)
    $0.backgroundColor = UIColor(r: 238, g: 238, b: 238)
    $0.layer.cornerRadius = 4
    $0.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
    $0.contentEdgeInsets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
  }
  
  let checkButton = UIButton().then {
    $0.setImage(UIImage(named: "img_check_off"), for: .normal)
  }
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.selectionStyle = .none
    self.addSubViews(
      containerView, emojiLabel, titleLabel, deadlineLabel,
      tagButton, checkButton
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
      make.top.equalTo(self.titleLabel.snp.bottom).offset(3)
    }
    
    self.tagButton.snp.makeConstraints { make in
      make.left.equalTo(self.deadlineLabel.snp.right).offset(7)
      make.centerY.equalTo(self.deadlineLabel)
    }
    
    self.checkButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.containerView)
      make.right.equalTo(self.containerView).offset(-16)
    }
  }
}
