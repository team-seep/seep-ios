import UIKit
import Combine

extension HomeFilterHeaderViewModel {
    struct Input {
        let didTapCategory = PassthroughSubject<Category, Never>()
        let updateCategory = PassthroughSubject<Category, Never>()
        let didTapSortOrder = PassthroughSubject<Void, Never>()
        let selectSortOrder = PassthroughSubject<HomeSortOrder, Never>()
        let didTapOnlyFinished = PassthroughSubject<Void, Never>()
        let didTapViewType = PassthroughSubject<Void, Never>()
        let didTapSearch = PassthroughSubject<Void, Never>()
        let didTapPlaceMap = PassthroughSubject<Void, Never>()
        let didTapAppLock = PassthroughSubject<Void, Never>()
        /// 잠금 시트에서 잠금을 켜고 끄면 아이콘을 바꾼다 (GH-46 R-1)
        let updateAppLock = PassthroughSubject<Bool, Never>()
    }
    
    struct Output {
        let category = CurrentValueSubject<Category, Never>(.wantToDo)
        let sortOrder = CurrentValueSubject<HomeSortOrder, Never>(.deadlineOrder)
        let onlyFinished = CurrentValueSubject<Bool, Never>(false)
        let viewType: CurrentValueSubject<ViewType, Never>
        /// 가고 싶어요 탭에서만 지도 버튼을 보인다 (GH-31 R-5)
        let isPlaceMapVisible = CurrentValueSubject<Bool, Never>(false)
        /// 켜져 있으면 자물쇠를 `lock.fill` `seepBlue` 로 그린다 (GH-46 R-1)
        let isAppLockEnabled: CurrentValueSubject<Bool, Never>
        
        // Relay
        let updateCategory = PassthroughSubject<Category, Never>()
        let didTapSortOrder = PassthroughSubject<Void, Never>()
        let updateOnlyFinished = PassthroughSubject<Bool, Never>()
        let updateViewType = PassthroughSubject<ViewType, Never>()
        let didTapSearch = PassthroughSubject<Void, Never>()
        let didTapPlaceMap = PassthroughSubject<Void, Never>()
        let didTapAppLock = PassthroughSubject<Void, Never>()
    }
    
    struct Config {
        let viewType: ViewType
        let isAppLockEnabled: Bool
    }
}

final class HomeFilterHeaderViewModel {
    let identifier = "HomeFilterHeaderViewModel"
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()
    
    init(config: Config) {
        self.output = Output(viewType: .init(config.viewType), isAppLockEnabled: .init(config.isAppLockEnabled))
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
        
        input.updateCategory
            .subscribe(output.category)
            .store(in: &cancellables)
        
        output.category
            .map { $0 == .wantToGo }
            .removeDuplicates()
            .subscribe(output.isPlaceMapVisible)
            .store(in: &cancellables)
        
        input.didTapPlaceMap
            .subscribe(output.didTapPlaceMap)
            .store(in: &cancellables)
        
        input.didTapAppLock
            .subscribe(output.didTapAppLock)
            .store(in: &cancellables)
        
        input.updateAppLock
            .subscribe(output.isAppLockEnabled)
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
        
        input.didTapSearch
            .subscribe(output.didTapSearch)
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
