import RxSwift
import RxCocoa
import ReactorKit
import UIKit

final class SignupReactor: Reactor {
    enum Action {
        case tapNicknameProfileType(NicknameProfileType)
        case inputNickname(String)
        case inputPhoto(UIImage)
        case tapSignup
    }
    
    enum Mutation {
        case setNicknameProfileType(NicknameProfileType)
        case setNickname(String)
        case setPhoto(UIImage)
        case goToMain
    }
    
    struct State {
        var nicknameProfileType: NicknameProfileType = .first
        var photo: UIImage?
        var nickname = ""
        var signupButtonState: WriteButton.WriteButtonState = .initial
    }
    
    let initialState: State
    let goToMainPublisher = PublishRelay<Void>()
    
    init(
        initialState: State = State()
    ) {
        self.initialState = initialState
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .tapNicknameProfileType(let nicknameProfileType):
            return .just(.setNicknameProfileType(nicknameProfileType))
            
        case .inputNickname(let nickname):
            return .just(.setNickname(nickname))
            
        case .inputPhoto(let photo):
            return .just(.setPhoto(photo))
            
        case .tapSignup:
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
            
        case .goToMain:
            self.goToMainPublisher.accept(())
        }
        
        return newState
    }
}
