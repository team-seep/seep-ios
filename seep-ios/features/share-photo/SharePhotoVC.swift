import Foundation

class SharePhotoVC: BaseVC {
  
  private let sharePhotoView = SharePhotoView()
  
  static func instance() -> SharePhotoVC {
    return SharePhotoVC(nibName: nil, bundle: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.addSubview(sharePhotoView)
    self.sharePhotoView.snp.makeConstraints { make in
      make.edges.equalTo(0)
    }
  }
}
