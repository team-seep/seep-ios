import UIKit
import Photos

class SharePhotoCell: BaseCollectionViewCell {
  
  static let registerId = "\(SharePhotoCell.self)"
  static let size = CGSize(
    width: (UIScreen.main.bounds.width - 2) / 3,
    height: (UIScreen.main.bounds.width - 2) / 3
  )
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
      contentMode: .aspectFit,
      options: options) { (image, info) in
      guard let image = image else { return }
      self.photo.image = image
    }
  }
}
