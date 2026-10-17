import UIKit
import Photos

class SharePhotoCell: BaseCollectionViewCell {
  
  static let registerId = "\(SharePhotoCell.self)"
  static let spacing: CGFloat = 1

  /// 화면 폭이 아니라 사진 목록(컬렉션뷰) 폭 기준. 넓은 시트(듀오 안쪽 등)에서는 열을 늘려 셀이 과하게 커지지 않게 한다.
  static func size(containerWidth: CGFloat) -> CGSize {
    let columnCount: CGFloat
    switch containerWidth {
    case ..<600:
      columnCount = 3
    case ..<800:
      columnCount = 4
    default:
      columnCount = 5
    }
    let length = floor((containerWidth - spacing * (columnCount - 1)) / columnCount)
    return CGSize(width: max(length, 0), height: max(length, 0))
  }
  var imageRequestId: PHImageRequestID?
  
  let photo = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
  }
  
  let dimmedView = UIView().then{
    $0.backgroundColor = .black.withAlphaComponent(0.6)
    $0.isHidden = true
  }
  
  let selectedMarker = UIImageView().then {
    $0.image = .icCheckOn
    $0.isHidden = true
  }
  
  override var isSelected: Bool {
    didSet {
      self.dimmedView.isHidden = !self.isSelected
      self.selectedMarker.isHidden = !self.isSelected
    }
  }
  
  
  override func prepareForReuse() {
    if let imageRequestId = self.imageRequestId {
      PHImageManager.default().cancelImageRequest(imageRequestId)
    }
    super.prepareForReuse()
  }
  
  override func setup() {
    self.backgroundColor = .gray
    self.addSubViews(photo, dimmedView, selectedMarker)
  }
  
  override func bindConstraints() {
    self.photo.snp.makeConstraints { make in
      make.edges.equalTo(0)
    }
    
    self.dimmedView.snp.makeConstraints { make in
      make.edges.equalTo(0)
    }
    
    self.selectedMarker.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
  
  func bind(asset: PHAsset) {
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true

    self.imageRequestId = PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
      contentMode: .aspectFill,
      options: options) { (image, info) in
      guard let image = image else { return }
      self.photo.image = image
    }
  }
}
