import FirebaseRemoteConfig
import RxSwift

protocol RemoteConfigServiceProtocol {
    
    func fetchNoticeLink() -> Observable<String>
}

struct RemoteConfigService: RemoteConfigServiceProtocol {
    
    private let instance = RemoteConfig.remoteConfig()
    
    func fetchNoticeLink() -> Observable<String> {
        return Observable.create { observer in
            self.instance.fetch(withExpirationDuration: 1800) { (status, error) in
                if status == .success {
                    self.instance.activate { (_, _) in
                        let noticeLink = self.instance["noticeLink"].stringValue ?? ""
                        
                        observer.onNext(noticeLink)
                        observer.onCompleted()
                    }
                } else {
                    if let remoteConfigError = error {
                        observer.onError(remoteConfigError)
                    } else {
                        //            observer.onError()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
