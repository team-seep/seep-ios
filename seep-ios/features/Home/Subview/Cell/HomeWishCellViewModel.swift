import Combine

extension HomeWishCellViewModel {
    struct Input {
        let didTapFinish = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        let wish: Wish
        let viewType: ViewType
        let didTapFinish = PassthroughSubject<Wish, Never>()
    }
    
    struct Config {
        let wish: Wish
        let viewType: ViewType
    }
    
    struct Dependency {
        init() {
            
        }
    }
}

final class HomeWishCellViewModel {
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    private let dependency: Dependency
    
    init(config: Config, dependency: Dependency = Dependency()) {
        self.output = Output(wish: config.wish, viewType: config.viewType)
        self.dependency = dependency
        
        bind()
    }
    
    private func bind() {
        input.didTapFinish
            .withUnretained(self)
            .filter({ (owner: HomeWishCellViewModel, _) in
                return !owner.output.wish.isSuccess
            })
            .sink(receiveValue: { (owner: HomeWishCellViewModel, _) in
                owner.output.didTapFinish.send(owner.output.wish)
            })
            .store(in: &cancellables)
    }
}

extension HomeWishCellViewModel: Hashable {
    static func == (lhs: HomeWishCellViewModel, rhs: HomeWishCellViewModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(output.wish)
        hasher.combine(output.viewType)
    }
}
