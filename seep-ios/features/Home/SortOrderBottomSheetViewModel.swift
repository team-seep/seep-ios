import Combine

extension SortOrderBottomSheetViewModel {
    struct Input {
        let didTapSortOrder = PassthroughSubject<HomeSortOrder, Never>()
    }
    
    struct Output {
        let didTapSortOrder = PassthroughSubject<HomeSortOrder, Never>()
        let route = PassthroughSubject<Route, Never>()
    }
    
    enum Route {
        case dismiss
    }
}

final class SortOrderBottomSheetViewModel {
    let input = Input()
    let output = Output()
    var cancellables = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    private func bind() {
        input.didTapSortOrder
            .withUnretained(self)
            .sink { (owner: SortOrderBottomSheetViewModel, sortOrder: HomeSortOrder) in
                owner.output.didTapSortOrder.send(sortOrder)
                owner.output.route.send(.dismiss)
            }
            .store(in: &cancellables)
    }
}
