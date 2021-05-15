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
    $0.font = .appleUltraLight(size: 24)
    $0.textColor = .black
  }
  
  let ddayContainer = UIView().then {
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOffset = CGSize(width: 0, height: 10)
    $0.layer.shadowOpacity = 0.25
    $0.layer.shadowRadius = 12
  }

  let ddayLabel = PaddingLabel(
    topInset: 4,
    bottomInset: 1,
    leftInset: 9,
    rightInset: 9
  ).then {
    $0.textColor = .white
    $0.font = .appleSemiBold(size: 22)
    $0.text = "D-Day"
    $0.backgroundColor = .gray5
    $0.layer.cornerRadius = 12
    $0.layer.masksToBounds = true
  }
  
  let emojiButton = ShareCategoryButton().then {
    $0.setTitle("share_photo_emoji".localized, for: .normal)
  }
  
  let buttonDividorView = UIView().then{
    $0.backgroundColor = UIColor(r: 238, g: 238, b: 238)
  }
  
  let photoButton = ShareCategoryButton().then {
    $0.setTitle("share_photo_album".localized, for: .normal)
  }
  
  let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  ).then {
    let layout = UICollectionViewFlowLayout()
    
    layout.itemSize = SharePhotoCell.size
    layout.minimumInteritemSpacing = 1
    layout.minimumLineSpacing = 1
    $0.collectionViewLayout = layout
    $0.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    $0.register(SharePhotoCell.self, forCellWithReuseIdentifier: SharePhotoCell.registerId)
  }
  
  
  override func setup() {
    self.backgroundColor = .white
    self.ddayContainer.addSubViews(ddayLabel)
    self.photoContainer.addSubViews(
      dateLabel, logoImage, emojiLabel, titleLabel,
      ddayContainer
    )
    self.addSubViews(
      photoContainer, emojiButton, buttonDividorView, photoButton,
      collectionView
    )
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
    
    self.titleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(21)
      make.bottom.equalToSuperview().offset(-21)
    }
    
    self.ddayLabel.snp.makeConstraints { make in
      make.left.equalTo(self.titleLabel)
      make.bottom.equalTo(self.titleLabel.snp.top).offset(-13)
    }
    
    self.ddayContainer.snp.makeConstraints { make in
      make.edges.equalTo(self.ddayLabel)
    }
    
    self.buttonDividorView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalTo(1)
      make.height.equalTo(30)
      make.top.equalTo(self.photoContainer.snp.bottom).offset(6)
    }
    
    self.emojiButton.snp.makeConstraints { make in
      make.left.equalToSuperview()
      make.right.equalTo(self.buttonDividorView.snp.left)
      make.top.equalTo(self.photoContainer.snp.bottom)
      make.height.equalTo(42)
    }
    
    self.photoButton.snp.makeConstraints { make in
      make.left.equalTo(self.buttonDividorView.snp.right)
      make.right.equalToSuperview()
      make.top.bottom.equalTo(self.emojiButton)
    }
    
    self.collectionView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(self.emojiButton.snp.bottom)
    }
  }
}
