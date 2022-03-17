import UIKit

final class SignupViewController: BaseVC {
    private let signupView = SignupView()
    
    static func instance() -> SignupViewController {
        return SignupViewController(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = self.signupView
    }
    
    override func bindEvent() {
        self.signupView.profileView.rx.tapCameraButton
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                AlertUtils.showImagePicker(controller: self, picker: UIImagePickerController())
            })
            .disposed(by: self.eventDisposeBag)
    }
}
