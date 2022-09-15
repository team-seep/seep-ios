import UIKit

import ReactorKit

final class SignupViewController: BaseVC, View {
    private let signupView = SignupView()
    private let signupReactor = SignupReactor()
    
    static func instance() -> SignupViewController {
        return SignupViewController(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = self.signupView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.signupReactor
    }
    
    override func bindEvent() {
        self.signupReactor.presentPhotoBottomSheet
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isPhotoExisted in
                guard let self = self else { return }
                
                AlertUtils.showImagePicker(controller: self, picker: UIImagePickerController())
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: SignupReactor) {
        // Bind action
        self.signupView.profileSwitch.rx.nicknameProfileType
            .map { Reactor.Action.tapNicknameProfileType($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.signupView.nicknameField.rx.text
            .map { Reactor.Action.inputNickname($0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.signupView.profileView.rx.tapCameraButton
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.tapCamera }
            .bind(to: reactor.action)
            .disposed(by: self.eventDisposeBag)
        
        self.signupView.signupButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.tapSignup }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Bind state
        reactor.state
            .map { ($0.nickname, $0.nicknameProfileType) }
            .asDriver(onErrorJustReturn: ("", .first))
            .drive(self.signupView.profileView.rx.nickname)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.photo }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(self.signupView.profileView.rx.image)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isSignupButtonEnable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.signupView.signupButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
    }
}
