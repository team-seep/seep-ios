import UIKit
import Combine

class BaseViewController: UIViewController {
    var cancellables = Set<AnyCancellable>()

    /// 페이지뷰 로그 화면명. `.empty` 면 보내지 않는다.
    var screenName: ScreenName { .empty }

    override func viewDidLoad() {
        super.viewDidLoad()
        sendPageView()
    }

    func sendPageView() {
        guard screenName != .empty else { return }
        LogManager.shared.sendPageView(screen: screenName, type: Self.self)
    }
    
    func showErrorAlert(_ error: Error) {
        let message: String
        if let localizedError = error as? LocalizedError,
           let errorDescription = localizedError.errorDescription {
            message = errorDescription
        } else {
            message = error.localizedDescription
        }
        
        AlertUtils.show(viewController: self, title: nil, message: message)
    }
}
