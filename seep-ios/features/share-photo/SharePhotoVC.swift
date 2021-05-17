import RxSwift
import ReactorKit

protocol SharePhotoDelegate: AnyObject {
  
  func onSuccessSave()
}

class SharePhotoVC: BaseVC, View {
  
  private let sharePhotoView = SharePhotoView()
  private let sharePhotoReactor: SharePhotoReactor
  weak var delegate: SharePhotoDelegate?
  
  init(wish: Wish) {
    self.sharePhotoReactor = SharePhotoReactor(
      wish: wish,
      userDefaults: UserDefaultsUtils()
    )
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
    // MARK: Bind event
    self.sharePhotoView.cancelButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.dismiss)
      .disposed(by: self.disposeBag)
    
    self.sharePhotoView.doubleTapGesture.rx.event
      .map { _ in SharePhotoReactor.Action.doubleTapPhoto }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
    
    self.sharePhotoView.shareButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.savePhotoToAlbum)
      .disposed(by: self.disposeBag)
    
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
      .distinctUntilChanged()
      .do(onNext: self.sharePhotoView.setCollectionViewHidden(by:))
      .bind(to: self.sharePhotoView.shareTypeSwitchButton.rx.selectType)
      .disposed(by: self.disposeBag)
    
    reactor.state
      .map { $0.photos }
      .distinctUntilChanged()
      .bind(to: self.sharePhotoView.collectionView.rx.items(
              cellIdentifier: SharePhotoCell.registerId,
              cellType: SharePhotoCell.self
      )) { row, asset, cell in
        cell.bind(asset: asset)
      }
      .disposed(by: self.disposeBag)
    
    reactor.state
      .map { $0.selectedPhoto }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.sharePhotoView.setPhotoBackground(asset:))
      .disposed(by: self.disposeBag)
    
    reactor.state
      .map { $0.isTooltipShown }
      .distinctUntilChanged()
      .filter { $0 == false }
      .observeOn(MainScheduler.instance)
      .bind { [weak self] _ in
        guard let self = self else { return }
        self.sharePhotoView.showTooltip { [weak self] isCompleted in
          guard let self = self else { return }
          
          if isCompleted {
            Observable.just(SharePhotoReactor.Action.tooltipDisappeared)
              .bind(to: reactor.action)
              .disposed(by: self.disposeBag)
          }
        }
      }
      .disposed(by: self.disposeBag)
    
    reactor.state
      .map{ $0.isPhotoTextColorBlack }
      .distinctUntilChanged()
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.sharePhotoView.setPhotoTextColor(isBlack:))
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
  
  private func dismiss() {
    self.dismiss(animated: true, completion: nil)
  }
  
  private func gotoAppPrivacySettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else {
      return
    }
    
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
  
  private func savePhotoToAlbum() {
    let image = self.sharePhotoView.photoContainer.asImage()
    
    UIImageWriteToSavedPhotosAlbum(
      image,
      self,
      #selector(saveError(_:didFinishSavingWithError:contextInfo:)),
      nil
    )
  }
  
  @objc func saveError(
    _ image: UIImage,
    didFinishSavingWithError error: Error?,
    contextInfo: UnsafeRawPointer
  ) {
    if let error = error {
      print("error: \(error.localizedDescription)")
    } else {
      self.dismiss(animated: true) {
        self.delegate?.onSuccessSave()
      }
    }
  }
}
