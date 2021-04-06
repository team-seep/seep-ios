import UIKit

class ToastView: BaseView {
  
  let messageLabel = UILabel().then {
    $0.text = "👏 완료했어요! 짝짝 축하합니다!"
    $0.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 15)
    $0.textColor = .white
  }
  
  let actionButton = UIButton().then {
    $0.setTitle("완료 목록보기", for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 12)
    $0.setTitleColor(.white, for: .normal)
  }
  
  override func setup() {
    self.layer.cornerRadius = 8
    self.layer.masksToBounds = true
    self.backgroundColor = .gray5
    self.addSubViews(messageLabel, actionButton)
  }
  
  override func bindConstraints() {
    self.messageLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(18)
      make.right.equalTo(self.actionButton.snp.left).offset(-20)
      make.centerY.equalToSuperview()
    }
    
    self.actionButton.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-20)
      make.centerY.equalToSuperview()
    }
  }
}
