import UIKit
import Photos

import SnapKit

class SharePhotoView: BaseView {

  private enum Layout {
    static let emojiFontSize: CGFloat = 150
    /// 기존 아이폰 카드(375pt)에서 이모지 150pt 비율. 카드가 줄어들 때 이모지가 D-day·제목을 덮지 않게 같이 줄인다.
    static let emojiFontRatio: CGFloat = 150 / 375
    static let shareButtonHeight: CGFloat = 50
    static let shareButtonBottomOffset: CGFloat = 24
    static let shareButtonTopSpacing: CGFloat = 12
  }

  private var photoListMinHeightConstraint: Constraint?

  let doubleTapGesture = UITapGestureRecognizer().then {
    $0.numberOfTapsRequired = 2
  }
  
  let topIndicator = UIView().then {
    $0.backgroundColor = .gray3
    $0.layer.cornerRadius = 2
  }
  
  let titleLabel = UILabel().then {
    $0.font = .appleLight(size: 20)
    $0.textColor = .gray5
    $0.text = "share_photo_title".localized
  }
  
  let cancelButton = UIButton().then {
    $0.setTitle("share_photo_dismiss".localized, for: .normal)
    $0.titleLabel?.font = .appleRegular(size: 14)
    $0.setTitleColor(.gray4, for: .normal)
  }
  
  let topDividor = UIView().then {
    $0.backgroundColor = UIColor(r: 246, g: 246, b: 246)
  }
  
  let photoContainer = UIView().then {
    $0.backgroundColor = UIColor(r: 207, g: 164, b: 110)
    $0.isUserInteractionEnabled = true
  }
  
  let imageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
    $0.isHidden = true
  }
  
  let dateLabel = UILabel().then {
    $0.font = .appleSemiBold(size: 16)
    $0.textColor = .black
  }
  
  let logoImage = UIImageView().then {
    $0.image = .icLogoBlack
  }
  
  let emojiLabel = UILabel().then {
    $0.font = .systemFont(ofSize: Layout.emojiFontSize)
  }
  
  let photoTitleLabel = UILabel().then {
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
    $0.backgroundColor = .gray5
    $0.layer.cornerRadius = 12
    $0.layer.masksToBounds = true
  }
  
  let tooltipView = PaddingLabel(
    topInset: 6,
    bottomInset: 4,
    leftInset: 10,
    rightInset: 10
  ).then {
    $0.font = .appleRegular(size: 14)
    $0.textColor = .black
    $0.text = "share_photo_tooltip".localized
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 15
    $0.layer.masksToBounds = true
    $0.isHidden = true
  }
  
  let bottomDividorView = UIView().then {
    $0.backgroundColor = UIColor(r: 246, g: 246, b: 246)
  }
  
  let shareTypeSwitchButton = ShareTypeSwitchView()
  
  let emojiCollectionView = UIView().then {
    $0.backgroundColor = UIColor(r: 246, g: 246, b: 246)
  }
  
  let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  ).then {
    let layout = UICollectionViewFlowLayout()
    
    layout.itemSize = .zero
    layout.minimumInteritemSpacing = SharePhotoCell.spacing
    layout.minimumLineSpacing = SharePhotoCell.spacing
    $0.collectionViewLayout = layout
    $0.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    $0.register(SharePhotoCell.self, forCellWithReuseIdentifier: SharePhotoCell.registerId)
  }
  
  let shareButton = UIButton().then {
    $0.titleLabel?.font = .appleExtraBold(size: 17)
    $0.setTitle("share_photo_button".localized, for: .normal)
    $0.backgroundColor = .tennisGreen
    $0.layer.cornerRadius = 25
    $0.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
  }
  
  
  override func setup() {
    self.backgroundColor = .white
    self.ddayContainer.addSubViews(ddayLabel)
    self.photoContainer.addSubViews(
      imageView, dateLabel, logoImage, emojiLabel,
      photoTitleLabel, ddayContainer, tooltipView
    )
    self.photoContainer.addGestureRecognizer(self.doubleTapGesture)
    self.addSubViews(
      topIndicator, titleLabel, cancelButton, photoContainer,
      topDividor, shareTypeSwitchButton, collectionView, emojiCollectionView,
      bottomDividorView, shareButton
    )
  }
  
  override func bindConstraints() {
    self.topIndicator.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalTo(48)
      make.height.equalTo(4).priority(.high)
      make.top.equalToSuperview().offset(9).priority(.high)
    }
    
    self.titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.topIndicator.snp.bottom).offset(12)
    }
    
    self.cancelButton.snp.makeConstraints { make in
      make.centerY.equalTo(self.titleLabel)
      make.right.equalToSuperview().offset(-20)
    }
    
    self.topDividor.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.bottom.equalTo(self.photoContainer.snp.top)
      make.height.equalTo(1)
    }
    
    // 카드는 시트 폭 기준 정사각형. 시트가 낮으면(듀오 안쪽 등) 사진 목록 최소 높이를 지키도록 줄어든다.
    self.photoContainer.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.titleLabel.snp.bottom).offset(10)
      make.height.equalTo(self.photoContainer.snp.width)
      make.width.lessThanOrEqualToSuperview()
      make.width.equalToSuperview().priority(.medium)
    }
    
    self.imageView.snp.makeConstraints { make in
      make.edges.equalTo(self.photoContainer)
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
    
    self.photoTitleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(21)
      make.bottom.equalToSuperview().offset(-21)
    }
    
    self.ddayLabel.snp.makeConstraints { make in
      make.left.equalTo(self.photoTitleLabel)
      make.bottom.equalTo(self.photoTitleLabel.snp.top).offset(-13)
    }
    
    self.ddayContainer.snp.makeConstraints { make in
      make.edges.equalTo(self.ddayLabel)
    }
    
    self.tooltipView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.height.equalTo(30)
    }
    
    self.shareTypeSwitchButton.snp.makeConstraints { make in
      make.top.equalTo(self.photoContainer.snp.bottom)
      make.left.right.equalToSuperview()
    }
    
    self.bottomDividorView.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.top.equalTo(self.shareTypeSwitchButton)
      make.height.equalTo(1)
    }
    
    self.collectionView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.top.equalTo(self.shareTypeSwitchButton.snp.bottom)
      self.photoListMinHeightConstraint = make.height.greaterThanOrEqualTo(0).priority(999).constraint
    }
    
    self.emojiCollectionView.snp.makeConstraints { make in
      make.edges.equalTo(self.collectionView)
    }
    
    self.shareButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.height.equalTo(Layout.shareButtonHeight)
      make.bottom.equalTo(safeAreaLayoutGuide).offset(-Layout.shareButtonBottomOffset)
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.updatePhotoListLayout()
    self.updateEmojiFontSize()
  }
  
  func bind(wish: Wish) {
    if let endDate = wish.endDate {
        self.dateLabel.text = DateUtils.toString(format: "yyyy.MM.dd", date: endDate)
        
        let remainDay = Calendar.current.dateComponents([.day], from: Date().startOfDay, to: endDate.startOfDay).day ?? -1
        
        if remainDay < 0 {
          self.ddayLabel.text = "D+\(abs(remainDay))"
        } else if remainDay == 0 {
          self.ddayLabel.text = "D-Day"
        } else if remainDay <= 365 {
          self.ddayLabel.text = "D-\(remainDay)"
        } else {
          self.ddayLabel.text = "home_in_far_furture".localized
        }
    }
    self.dateLabel.isHidden = wish.endDate == nil
    self.ddayLabel.isHidden = wish.endDate == nil
    self.photoTitleLabel.text = wish.title
    self.emojiLabel.text = wish.emoji
    self.photoContainer.backgroundColor = wish.emoji.image()?.averageColor
  }
  
  func setCollectionViewHidden(by type: ShareTypeSwitchView.ShareType) {
    self.collectionView.isHidden = type == .emoji
    self.emojiCollectionView.isHidden = type == .photo
    self.imageView.isHidden = type == .emoji
    self.emojiLabel.isHidden = type == .photo
  }
  
  func setPhotoBackground(asset: PHAsset?) {
    guard let asset = asset else { return }
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true

    PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
      contentMode: .aspectFit,
      options: options) { (image, info) in
      guard let image = image else { return }
      self.imageView.image = image
    }
  }
  
  func showTooltip(onDismiss: @escaping (Bool) -> Void) {
    self.tooltipView.isHidden = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
      guard let self = self else { return }
      UIView.transition(
        with: self.tooltipView,
        duration: 0.3,
        options: .curveEaseInOut
      ) { [weak self] in
        guard let self = self else { return }
        self.tooltipView.alpha = 0
      } completion: { isComplete in
        onDismiss(isComplete)
      }
    }
  }
  
  /// 셀 크기는 시트 폭 기준으로 계산하고, 공유 버튼에 가리지 않는 사진 목록이 최소 한 줄은 남게 한다.
  private func updatePhotoListLayout() {
    guard let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
    let itemSize = SharePhotoCell.size(containerWidth: self.bounds.width)
    if layout.itemSize != itemSize {
      layout.itemSize = itemSize
      layout.invalidateLayout()
    }

    let shareButtonArea = Layout.shareButtonHeight
      + Layout.shareButtonBottomOffset
      + Layout.shareButtonTopSpacing
      + self.safeAreaInsets.bottom
    let bottomInset = shareButtonArea - self.safeAreaInsets.bottom
    if self.collectionView.contentInset.bottom != bottomInset {
      self.collectionView.contentInset.bottom = bottomInset
    }

    let minHeight = itemSize.height + shareButtonArea
    if self.photoListMinHeightConstraint?.layoutConstraints.first?.constant != minHeight {
      self.photoListMinHeightConstraint?.update(offset: minHeight)
    }
  }

  private func updateEmojiFontSize() {
    let cardWidth = self.photoContainer.bounds.width
    guard cardWidth > 0 else { return }
    let fontSize = min(Layout.emojiFontSize, floor(cardWidth * Layout.emojiFontRatio))
    if self.emojiLabel.font.pointSize != fontSize {
      self.emojiLabel.font = .systemFont(ofSize: fontSize)
    }
  }

  func setPhotoTextColor(isBlack: Bool) {
    self.dateLabel.textColor = isBlack ? .gray5 : .white
    self.photoTitleLabel.textColor = isBlack ? .gray5 : .white
    self.logoImage.image = isBlack ? .icLogoBlack : .icLogoWhite
  }
}
