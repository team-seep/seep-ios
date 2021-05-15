import UIKit

class SharePhotoCell: BaseCollectionViewCell {
  
  static let registerId = "\(SharePhotoCell.self)"
  static let size = CGSize(
    width: (UIScreen.main.bounds.width - 2) / 3,
    height: (UIScreen.main.bounds.width - 2) / 3
  )
  
  let photo = UIImageView().then {
    $0.contentMode = .scaleAspectFill
  }
  
  let dimmedView = UIView().then{
    $0.backgroundColor = .black.withAlphaComponent(0.6)
    $0.isHidden = true
  }
  
  let selectedMarker = UIImageView().then {
    $0.image = .icCheckOn
    $0.isHidden = true
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
}
