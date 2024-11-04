import Foundation

import RxSwift
import RxCocoa
import ReactorKit

final class HomeReactor: Reactor {
    enum Action {
        case viewWillAppear
        case tapSuccessCountButton
        case tapCategory(Category)
        case tapViewTypeButton
        case tapWriteButton
    }
    
    enum Mutation {
        case filterCategory(Category)
        case setViewType(ViewType)
        case setSuccessCount(Int)
        case setWishCount(Int)
        case pushFinish(category: Category)
        case presentWrite(Category)
        case showNotice(url: String)
    }
    
    struct State {
        var wishCount: Int = 0
        var successCount: Int = 0
        var category: Category = .wantToDo
        var viewType: ViewType = .list
    }
    
    let initialState = State()
    let presentWritePublisher = PublishRelay<Category>()
    let pushFinishPublisher = PublishRelay<Category>()
    let showNoticePublisher = PublishRelay<String>()
    private let wishService: WishServiceProtocol
    private let userDefaults: UserDefaultsUtils
    
    
    init(
        wishService: WishServiceProtocol,
        userDefaults: UserDefaultsUtils
    ) {
        self.wishService = wishService
        self.userDefaults = userDefaults
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            let successCount = self.wishService.getFinishCount(category: self.currentState.category)
            let wishCount = self.wishService.getWishCount(category: self.currentState.category)
            
            return .merge([
                .just(.setWishCount(wishCount)),
                .just(.setSuccessCount(successCount)),
                .just(.setViewType(self.userDefaults.getViewType())),
                self.handleDeepkLink(urlString: self.userDefaults.getDeepLink())
            ])
            
        case .tapSuccessCountButton:
            return .just(.pushFinish(category: self.currentState.category))
            
        case .tapCategory(let category):
            let wishCount = self.wishService.getWishCount(category: category)
            let successCount = self.wishService.getFinishCount(category: category)
            
            return .concat([
                .just(.setWishCount(wishCount)),
                .just(.setSuccessCount(successCount)),
                .just(.filterCategory(category))
            ])
            
        case .tapViewTypeButton:
            let viewType = self.currentState.viewType.toggle()
            
            self.userDefaults.setViewType(viewType: viewType)
            return .just(.setViewType(viewType))
            
        case .tapWriteButton:
            return .just(.presentWrite(self.currentState.category))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .filterCategory(let category):
            newState.category = category
            
        case .setViewType(let viewType):
            newState.viewType = viewType
            
        case .setSuccessCount(let count):
            newState.successCount = count
            
        case .setWishCount(let count):
            newState.wishCount = count
            
        case .pushFinish(let category):
            self.pushFinishPublisher.accept(category)
            
        case .presentWrite(let category):
            self.presentWritePublisher.accept(category)
            
        case .showNotice(let url):
            self.showNoticePublisher.accept(url)
        }
        
        return newState
    }
    
    private func handleDeepkLink(urlString: String) -> Observable<Mutation> {
        self.userDefaults.setDeepLink(deepLink: "")
        guard !urlString.isEmpty,
              let urlComponents = URLComponents(string: urlString) else {
            return .empty()
        }
        
        if urlComponents.host == "add" {
            if let categoryQuery = urlComponents.queryItems?.first(where: { $0.name == "category" }),
               let category = Category(rawValue: categoryQuery.value ?? "") {
                
                return .just(.presentWrite(category))
            }
        }
        return .empty()
    }
}
