import UIKit
import Combine

extension HomeFilterHeaderViewModel {
    struct Input {
        let didTapCategory = PassthroughSubject<Category, Never>()
        let didTapSortOrder = PassthroughSubject<Void, Never>()
        let selectSortOrder = PassthroughSubject<HomeSortOrder, Never>()
        let didTapOnlyFinished = PassthroughSubject<Void, Never>()
        let didTapViewType = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        let category = CurrentValueSubject<Category, Never>(.wantToDo)
        let sortOrder = CurrentValueSubject<HomeSortOrder, Never>(.deadlineOrder)
        let onlyFinished = CurrentValueSubject<Bool, Never>(false)
        let viewType: CurrentValueSubject<ViewType, Never>
        
        // Relay
        let updateCategory = PassthroughSubject<Category, Never>()
        let didTapSortOrder = PassthroughSubject<Void, Never>()
        let updateOnlyFinished = PassthroughSubject<Bool, Never>()
        let updateViewType = PassthroughSubject<ViewType, Never>()
    }
    
    struct Config {
        let viewType: ViewType
    }
}

final class HomeFilterHeaderViewModel {
    let identifier = "HomeFilterHeaderViewModel"
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    
    init(config: Config) {
        self.output = Output(viewType: .init(config.viewType))
        bind()
    }
    
    private func bind() {
        input.didTapCategory
            .withUnretained(self)
            .sink(receiveValue: { (owner: HomeFilterHeaderViewModel, category: Category) in
                owner.output.category.send(category)
                owner.output.updateCategory.send(category)
            })
            .store(in: &cancellables)
        
        input.didTapSortOrder
            .subscribe(output.didTapSortOrder)
            .store(in: &cancellables)
        
        input.selectSortOrder
            .subscribe(output.sortOrder)
            .store(in: &cancellables)
        
        input.didTapOnlyFinished
            .withUnretained(self)
            .sink(receiveValue: { (owner: HomeFilterHeaderViewModel, _) in
                let isOnlyFinished = !owner.output.onlyFinished.value
                owner.output.onlyFinished.send(isOnlyFinished)
                owner.output.updateOnlyFinished.send(isOnlyFinished)
            })
            .store(in: &cancellables)
        
        input.didTapViewType
            .withUnretained(self)
            .sink(receiveValue: { (owner: HomeFilterHeaderViewModel, _) in
                let viewType = owner.output.viewType.value.toggle()
                owner.output.viewType.send(viewType)
                owner.output.updateViewType.send(viewType)
            })
            .store(in: &cancellables)
    }
}

extension HomeFilterHeaderViewModel: Hashable, Equatable {
    static func == (lhs: HomeFilterHeaderViewModel, rhs: HomeFilterHeaderViewModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
