import RxSwift
import RxRelay

class BaseReactor {
    let showErrorAlertPublisher = PublishRelay<Error>()
    let showLoadingPublisher = PublishRelay<Bool>()
}
