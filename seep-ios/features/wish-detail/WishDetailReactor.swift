import Foundation
import Combine

import RxSwift
import RxCocoa
import ReactorKit

final class WishDetailReactor: Reactor {
    enum Action {
        case tapEditButton
        case tapDeleteButton
        case tapCancelFinish
        case tapSharePhoto
        case updateWish(wish: Wish)
    }
  
    enum Mutation {
        case setWish(wish: Wish)
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
    let updateWishPublisher = PassthroughSubject<Wish, Never>()
    let deleteWishPublisher = PassthroughSubject<Wish, Never>()
    let cancelFinishPublisher = PassthroughSubject<Wish, Never>()
    var cancellables = Set<AnyCancellable>()
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
            deleteWishPublisher.send(currentState.wish)
            
            return .just(.popupWishCategory(self.currentState.wish.category))
            
        case .tapCancelFinish:
            self.wishService.cancelFinishWish(id: self.currentState.wish.id)
            cancelFinishPublisher.send(currentState.wish)
            
            return .just(.popupWishCategory(self.currentState.wish.category))
            
        case .tapSharePhoto:
            return .just(.presentSharePhoto)
            
        case .updateWish(let wish):
            updateWishPublisher.send(wish)
            return .just(.setWish(wish: wish))
        }
    }
  
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setWish(let wish):
            newState.wish = wish
            
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
