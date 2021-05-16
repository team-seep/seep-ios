import RxSwift
import RxCocoa
import ReactorKit
import Photos

class SharePhotoReactor: Reactor {
  
  enum Action {
    case tapEmojiButton
    case tapPhotoButton
    case selectPhoto(Int)
    case tapShareButton
  }
  
  enum Mutation {
    case setShareType(ShareTypeSwitchView.ShareType)
    case fetchAllPhotos([PHAsset])
    case setAlertMessage(String)
  }
  
  struct State {
    var shareType: ShareTypeSwitchView.ShareType = .emoji
    var photos: [PHAsset] = []
  }
  
  let initialState = State()
  let alertPublisher = PublishRelay<String>()
  
  init(wish: Wish) {
    
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
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
    default:
      return Observable.empty()
    }
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    
    switch mutation {
    case .setShareType(let shareType):
      newState.shareType = shareType
    case .fetchAllPhotos(let photos):
      newState.photos = photos
    case .setAlertMessage(let message):
      self.alertPublisher.accept(message)
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
    
    return .just(assets.objects(at: IndexSet(0..<assets.count - 1)))
  }
  
  private func handleError(error: Error) -> Observable<Mutation> {
    if let commonError = error as? CommonError {
      return .just(.setAlertMessage(commonError.description))
    } else{
      return .just(.setAlertMessage(error.localizedDescription))
    }
  }
}
