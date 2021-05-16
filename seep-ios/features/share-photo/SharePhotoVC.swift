import RxSwift
import ReactorKit

class SharePhotoVC: BaseVC, View {
  
  private let sharePhotoView = SharePhotoView()
  private let sharePhotoReactor: SharePhotoReactor
  
  
  init(wish: Wish) {
    self.sharePhotoReactor = SharePhotoReactor(wish: wish)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  static func instance(wish: Wish) -> SharePhotoVC {
    return SharePhotoVC(wish: wish)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.reactor = self.sharePhotoReactor
    self.view.addSubview(sharePhotoView)
    self.sharePhotoView.snp.makeConstraints { make in
      make.edges.equalTo(0)
    }
  }
  
  func bind(reactor: SharePhotoReactor) {
    // MARK: Bind action
    self.sharePhotoView.shareTypeSwitchButton.rx.tapEmojiButton
      .map { SharePhotoReactor.Action.tapEmojiButton }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.sharePhotoView.shareTypeSwitchButton.rx.tapPhotoButton
      .map { SharePhotoReactor.Action.tapPhotoButton }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    self.sharePhotoView.collectionView.rx.itemSelected
      .map { SharePhotoReactor.Action.selectPhoto($0.row) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    // MARK: Bind State
    reactor.state
      .map { $0.shareType }
      .do(onNext: self.sharePhotoView.setCollectionViewHidden(by:))
      .bind(to: self.sharePhotoView.shareTypeSwitchButton.rx.selectType)
      .disposed(by: self.disposeBag)
    
    reactor.state
      .map { $0.photos }
      .bind(to: self.sharePhotoView.collectionView.rx.items(
              cellIdentifier: SharePhotoCell.registerId,
              cellType: SharePhotoCell.self
      )) { row, asset, cell in
        cell.bind(asset: asset)
      }
      .disposed(by: self.disposeBag)
    
    reactor.alertPublisher
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.showDeniedAlert(message:))
      .disposed(by: self.disposeBag)
  }
  
  private func showDeniedAlert(message: String) {
    AlertUtils.showWithCancel(
      viewController: self,
      title: nil,
      message: message,
      onTapOk: { [weak self] in
        self?.gotoAppPrivacySettings()
    })
  }
  
  private func gotoAppPrivacySettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else {
      return
    }
    
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}
