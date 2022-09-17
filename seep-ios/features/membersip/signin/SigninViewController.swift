import UIKit

import ReactorKit

final class SigninViewController: BaseViewController, View, SigninCoordinator {
    private let signinView = SigninView()
    private let signinReactor = SigninReactor(
        appleSigninManager: AppleSigninManager.shared,
        kakaoSigninManager: KakaoSignInManager.shared,
        authenticationService: AuthenticationService(),
        userDefaults: UserDefaultsUtils()
    )
    private weak var coordinator: SigninCoordinator?
    
    static func instance() -> SigninViewController {
        return SigninViewController(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = self.signinView
        self.reactor = self.signinReactor
        self.coordinator = self
    }
    
    override func bindEvent() {
        self.signinReactor.pushSignupPublisher
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] in
                self?.coordinator?.pushSignup()
            })
            .disposed(by: self.eventDisposeBag)
        
        self.signinReactor.goToMainPublisher
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] in
                self?.coordinator?.goToMain()
            })
            .disposed(by: self.disposeBag)
        
        self.signinReactor.showErrorAlertPublisher
            .asDriver(onErrorJustReturn: BaseError.unknown)
            .drive(onNext: { [weak self] error in
                self?.coordinator?.showErrorAlert(error: error)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: SigninReactor) {
        // Bind Action
        self.signinView.appleButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.tapAppleButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.signinView.kakaoButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.tapKakaoButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.signinView.startWithoutSigninButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.tapContinueWithoutSignin }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    }
}
