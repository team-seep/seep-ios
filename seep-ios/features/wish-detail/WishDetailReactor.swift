import Foundation

import RxSwift
import RxCocoa
import ReactorKit

final class WishDetailReactor: Reactor {
    enum Action {
        case tapEditButton
        case tapDeleteButton
        case tapSharePhoto
    }
  
    enum Mutation {
        case pushEdit(wish: Wish)
        case presentSharePhoto
        case popupWishCategory(Category)
    }
  
    struct State {
        var wish: Wish
    }
  
    let initialState: State
    let pushWishEditPublisher = PublishRelay<Wish>()
    let popupWithCategoryPublisher = PublishRelay<Category>()
    let presentSharePhotoPublisher = PublishRelay<Wish>()
    private let wishService: WishServiceProtocol
    
    init(
        wish: Wish,
        wishService: WishServiceProtocol
    ) {
        self.initialState = State(wish: wish)
        self.wishService = wishService
    }
  
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .tapEditButton:
            return .just(.pushEdit(wish: self.currentState.wish))
            
        case .tapDeleteButton:
            self.wishService.deleteWish(id: self.currentState.wish.id)
            
            return .just(.popupWishCategory(self.currentState.wish.category))
            
        case .tapSharePhoto:
            return .just(.presentSharePhoto)
        }
    }
  
    func reduce(state: State, mutation: Mutation) -> State {
        let newState = state
        switch mutation {
        case .pushEdit(let wish):
            self.pushWishEditPublisher.accept(wish)
            
        case .presentSharePhoto:
            self.presentSharePhotoPublisher.accept(self.currentState.wish)
            
        case .popupWishCategory(let category):
            self.popupWithCategoryPublisher.accept(category)
        }
        
        return newState
    }
}
