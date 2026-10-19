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
        case updateSteps([WishStep])
        case updateSavings([WishSaving])
        case updatePlace(WishPlace?)
        case updatePhoto(fileName: String)
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
            // 수정 화면이 단계까지 담아 돌려준다 (R-19, R-20)
            updateWishPublisher.send(wish)
            return .just(.setWish(wish: wish))
            
        case .updateSteps(let steps):
            var wish = currentState.wish
            wish.steps = steps
            updateWishPublisher.send(wish)
            return .just(.setWish(wish: wish))
            
        case .updateSavings(let savings):
            // 수정 화면으로 넘길 위시가 최신 기록을 갖도록 (GH-16 R-7)
            var wish = currentState.wish
            wish.savings = savings
            updateWishPublisher.send(wish)
            return .just(.setWish(wish: wish))
            
        case .updatePlace(let place):
            // 수정 화면으로 넘길 위시·홈·지도가 최신 장소를 갖도록 (GH-31 R-4)
            var wish = currentState.wish
            wish.place = place
            updateWishPublisher.send(wish)
            return .just(.setWish(wish: wish))
            
        case .updatePhoto(let fileName):
            // 홈 그리드 셀과 수정 화면으로 넘길 위시가 최신 사진을 갖도록 (GH-36 R-6)
            var wish = currentState.wish
            wish.photoFileName = fileName
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
