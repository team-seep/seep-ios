import UIKit

import ReactorKit

final class SignupViewController: BaseVC, View, SignupCoordinator {
    private let signupView = SignupView()
    private let signupReactor = SignupReactor()
    private weak var coordinator: SignupCoordinator?
    private let imagePicker = UIImagePickerController()
    
    static func instance() -> SignupViewController {
        return SignupViewController(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = self.signupView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = self.signupReactor
        self.coordinator = self
        self.imagePicker.delegate = self
    }
    
    override func bindEvent() {
        self.signupReactor.presentPhotoBottomSheet
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isPhotoExisted in
                guard let self = self else { return }
                
                self.coordinator?.showImagePicker(
                    isPhotoNil: isPhotoExisted,
                    picker: self.imagePicker
                )
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
            .map { ($0.photo, $0.nickname.isEmpty) }
            .asDriver(onErrorJustReturn: (nil, true))
            .drive(self.signupView.profileView.rx.image)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.photo != nil }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.signupView.profileSwitch.rx.isEnable)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isSignupButtonEnable }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.signupView.signupButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
    }
}

extension SignupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let photo = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.signupReactor.action.onNext(.inputPhoto(photo))
        }
        
        picker.dismiss(animated: true)
    }
}
