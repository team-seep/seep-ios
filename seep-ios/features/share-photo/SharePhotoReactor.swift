import RxSwift
import RxCocoa
import ReactorKit
import Photos

class SharePhotoReactor: Reactor {
  
  enum Action {
    case tooltipDisappeared
    case doubleTapPhoto
    case tapEmojiButton
    case tapPhotoButton
    case selectPhoto(Int)
    case tapShareButton
  }
  
  enum Mutation {
    case setTooltipShown(Bool)
    case changePhotoTextColor
    case setShareType(ShareTypeSwitchView.ShareType)
    case fetchAllPhotos([PHAsset])
    case setSelectedPhoto(PHAsset)
    case setAlertMessage(String)
  }
  
  struct State {
    var isTooltipShown: Bool
    var isPhotoTextColorBlack = true
    var shareType: ShareTypeSwitchView.ShareType = .emoji
    var photos: [PHAsset] = []
    var selectedPhoto: PHAsset?
  }
  
  let initialState: State
  let userDefaults: UserDefaultsUtils
  let alertPublisher = PublishRelay<String>()
  
  init(wish: Wish, userDefaults: UserDefaultsUtils) {
    self.userDefaults = userDefaults
    self.initialState = State(isTooltipShown: userDefaults.getSharePhotoTooltipIsShow())
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tooltipDisappeared:
      self.userDefaults.setSharePhotoTooltipIsShow(isShown: true)
      return .just(.setTooltipShown(true))
    case .doubleTapPhoto:
      return .just(.changePhotoTextColor)
    case .tapEmojiButton:
      return .just(.setShareType(.emoji))
    case .tapPhotoButton:
      return self.getCurrentPhotosPermission()
        .flatMap { isGranged -> Observable<Mutation> in
          if isGranged {
            return .concat([
              self.fetchPhotos().map { Mutation.fetchAllPhotos($0) },
              .just(.setShareType(.photo))
            ])
          } else {
            return self.requestPhotoPermission()
              .flatMap { _ -> Observable<Mutation> in
                return .concat([
                  self.fetchPhotos().map { Mutation.fetchAllPhotos($0) },
                  .just(.setShareType(.photo))
                ])
              }
          }
        }
        .catchError(self.handleError(error:))
    case .selectPhoto(let index):
      let selectedPhoto = self.currentState.photos[index]
      
      return .just(.setSelectedPhoto(selectedPhoto))
    default:
      return Observable.empty()
    }
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    
    switch mutation {
    case .setTooltipShown(let isShown):
      newState.isTooltipShown = isShown
    case .changePhotoTextColor:
      newState.isPhotoTextColorBlack.toggle()
    case .setShareType(let shareType):
      newState.shareType = shareType
    case .fetchAllPhotos(let photos):
      newState.photos = photos
      if newState.selectedPhoto == nil {
        newState.selectedPhoto = photos[0]
      }
    case .setAlertMessage(let message):
      self.alertPublisher.accept(message)
    case .setSelectedPhoto(let asset):
      newState.selectedPhoto = asset
    }
    
    return newState
  }
  
  func getCurrentPhotosPermission() -> Observable<Bool> {
    let photoAuthorizationStatusStatus = PHPhotoLibrary.authorizationStatus()
    
    switch photoAuthorizationStatusStatus {
    case .authorized:
      return .just(true)
    case .denied:
      let deniedError = CommonError(desc: "share_photo_deny_message".localized)
      
      return .error(deniedError)
    case .notDetermined:
      return .just(false)
    case .restricted:
      let restrictedError = CommonError(desc: "share_photo_deny_message".localized)
      
      return .error(restrictedError)
    default:
      let unSupportedTypeError = CommonError(desc: "\(photoAuthorizationStatusStatus) is not supported")
      
      return .error(unSupportedTypeError)
    }
  }
  
  private func requestPhotoPermission() -> Observable<Void> {
    return Observable.create { observer in
      PHPhotoLibrary.requestAuthorization() { status in
        switch status {
        case .authorized:
          observer.onNext(())
          observer.onCompleted()
        case .denied:
          let deniedError = CommonError(desc: "share_photo_deny_message".localized)
          
          observer.onError(deniedError)
        default:
          let unSupportedTypeError = CommonError(desc: "\(status) is not supported")
          
          observer.onError(unSupportedTypeError)
        }
      }
      
      return Disposables.create()
    }
  }
  
  private func fetchPhotos() -> Observable<[PHAsset]> {
    let fetchOption = PHFetchOptions().then {
      $0.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    }
    let assets = PHAsset.fetchAssets(with: .image, options: fetchOption)
    
    if assets.count > 0 {
      return .just(assets.objects(at: IndexSet(0..<assets.count - 1)))
    } else {
      return .just([])
    }
  }
  
  private func handleError(error: Error) -> Observable<Mutation> {
    if let commonError = error as? CommonError {
      return .just(.setAlertMessage(commonError.description))
    } else{
      return .just(.setAlertMessage(error.localizedDescription))
    }
  }
}
