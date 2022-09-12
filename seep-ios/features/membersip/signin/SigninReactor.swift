import ReactorKit
import RxSwift
import RxRelay

final class SigninReactor: BaseReactor, Reactor {
    enum Action {
        case tapAppleButton
        case tapKakaoButton
        case tapContinueWithoutSignin
    }
    
    enum Mutation {
        case pushSignup
        case goToMain
        case showError(Error)
        case showLoading(isShow: Bool)
    }
    
    struct State {
        
    }
    
    let initialState: State
    let pushSignupPublisher = PublishRelay<Void>()
    let goToMainPublisher = PublishRelay<Void>()
    private let appleSigninManager: AppleSignInManagerProtocol
    private let kakaoSigninManager: KakaoSignInManagerProtocol
    private let authenticationService: AuthenticationServiceType
    private var userDefaults: UserDefaultsUtils
    
    init(
        appleSigninManager: AppleSignInManagerProtocol,
        kakaoSigninManager: KakaoSignInManager,
        authenticationService: AuthenticationServiceType,
        userDefaults: UserDefaultsUtils,
        state: State = State()
    ) {
        self.appleSigninManager = appleSigninManager
        self.kakaoSigninManager = kakaoSigninManager
        self.authenticationService = authenticationService
        self.userDefaults = userDefaults
        self.initialState = state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .tapAppleButton:
            return self.appleSigninManager.signIn()
                .flatMap { [weak self] token -> Observable<Mutation> in
                    guard let self = self else { return .error(BaseError.unknown) }
                    
                    return self.authenticationService.authorizeWithApple(token: token)
                        .do(onNext: { [weak self] response in
                            self?.userDefaults.token = response.accessToken
                        })
                        .map { _ in .goToMain }
                }
                .catch { error in
                    if let httpError = error as? HTTPError,
                       httpError == .notFound {
                        return .just(.pushSignup)
                    } else {
                        return .just(.showError(error))
                    }
                }
            
        case .tapKakaoButton:
            return self.kakaoSigninManager.signIn()
                .flatMap { [weak self] token -> Observable<Mutation> in
                    guard let self = self else { return .error(BaseError.unknown) }
                    
                    return self.authenticationService.authorizeWithKakao(token: token)
                        .do(onNext: { [weak self] response in
                            self?.userDefaults.token = response.accessToken
                        })
                        .map { _ in .goToMain }
                }
                .catch { error in
                    if let httpError = error as? HTTPError,
                       httpError == .notFound {
                        return .just(.pushSignup)
                    } else {
                        return .just(.showError(error))
                    }
                }
            
        case .tapContinueWithoutSignin:
            return .just(.goToMain)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .pushSignup:
            self.pushSignupPublisher.accept(())
            
        case .goToMain:
            self.goToMainPublisher.accept(())
            
        case .showError(let error):
            self.showErrorAlertPublisher.accept(error)
            
        case .showLoading(let isShow):
            self.showLoadingPublisher.accept(isShow)
        }
        
        return newState
    }
}
