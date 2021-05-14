import UIKit

class SharePhotoView: BaseView {
  
  let photoContainer = UIView().then {
    $0.backgroundColor = UIColor(r: 207, g: 164, b: 110)
  }
  
  let dateLabel = UILabel().then {
    $0.font = .appleSemiBold(size: 16)
    $0.textColor = .black
    $0.text = "2021.05.09"
  }
  
  let logoImage = UIImageView().then {
    $0.image = .icLogoBlack
  }
  
  let emojiLabel = UILabel().then {
    $0.text = "🍩"
    $0.font = .systemFont(ofSize: 100)
  }
  
  let titleLabel = UILabel().then {
    $0.text = "치팅데이기념 랜디스도넛"
    $0.font = .appleli
  }
  
  override func setup() {
    self.backgroundColor = .white
    self.photoContainer.addSubViews(dateLabel, logoImage, emojiLabel)
    self.addSubViews(photoContainer)
  }
  
  override func bindConstraints() {
    self.photoContainer.snp.makeConstraints { make in
      make.left.top.right.equalToSuperview()
      make.height.equalTo(UIScreen.main.bounds.width)
    }
    
    self.dateLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(19)
      make.top.equalToSuperview().offset(24)
    }
    
    self.logoImage.snp.makeConstraints { make in
      make.centerY.equalTo(self.dateLabel)
      make.right.equalToSuperview().offset(-17)
    }
    
    self.emojiLabel.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
}
