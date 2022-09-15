import RxSwift
import RxCocoa
import ReactorKit
import UIKit

final class SignupReactor: Reactor {
    enum Action {
        case tapNicknameProfileType(NicknameProfileType)
        case inputNickname(String)
        case inputPhoto(UIImage)
        case tapCamera
        case tapSignup
    }
    
    enum Mutation {
        case setNicknameProfileType(NicknameProfileType)
        case setNickname(String)
        case setPhoto(UIImage)
        case presentPhotoBottomSheet(isPhotoExisted: Bool)
        case setSignupButtonEnable(isEnable: Bool)
        case goToMain
    }
    
    struct State {
        var nicknameProfileType: NicknameProfileType
        var photo: UIImage?
        var nickname: String
        var isSignupButtonEnable: Bool
    }
    
    let initialState: State
    let goToMainPublisher = PublishRelay<Void>()
    let presentPhotoBottomSheet = PublishRelay<Bool>()
    
    init(
        initialState: State = State(
            nicknameProfileType: .first,
            photo: nil,
            nickname: "",
            isSignupButtonEnable: false
        )
    ) {
        self.initialState = initialState
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .tapNicknameProfileType(let nicknameProfileType):
            return .just(.setNicknameProfileType(nicknameProfileType))
            
        case .inputNickname(let nickname):
            return .merge([
                .just(.setNickname(nickname)),
                .just(.setSignupButtonEnable(isEnable: self.isValidSignupButton()))
            ])
            
        case .inputPhoto(let photo):
            return .just(.setPhoto(photo))
            
        case .tapCamera:
            let isPhotoExisted = self.currentState.photo != nil
            
            return .just(.presentPhotoBottomSheet(isPhotoExisted: isPhotoExisted))
            
        case .tapSignup:
            // TODO: 회원가입
            return .empty()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setNicknameProfileType(let nicknameProfileType):
            newState.nicknameProfileType = nicknameProfileType
            
        case .setNickname(let nickname):
            newState.nickname = nickname
            
        case .setPhoto(let photo):
            newState.photo = photo
            
        case .presentPhotoBottomSheet(let isPhotoExisted):
            self.presentPhotoBottomSheet.accept(isPhotoExisted)
            
        case .setSignupButtonEnable(let isEnable):
            newState.isSignupButtonEnable = isEnable
            
        case .goToMain:
            self.goToMainPublisher.accept(())
        }
        
        return newState
    }
    
    private func isValidSignupButton() -> Bool {
        return !self.currentState.nickname.isEmpty
    }
}
