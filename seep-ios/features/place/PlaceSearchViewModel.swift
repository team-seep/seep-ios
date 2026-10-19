import Foundation
import Combine

extension PlaceSearchViewModel {
    struct Input {
        let inputQuery = PassthroughSubject<String, Never>()
        let didTapCandidate = PassthroughSubject<Int, Never>()
    }

    struct Output {
        let screenName: ScreenName = .placeSearchBottomSheet
        let candidates = CurrentValueSubject<[PlaceCandidate], Never>([])
        /// 검색어가 있는데 후보가 없거나 검색이 실패했을 때 "찾는 장소가 없어요" (R-3)
        let isEmptyVisible = CurrentValueSubject<Bool, Never>(false)
        /// 후보를 골라 좌표까지 받은 장소. 섹션 ViewModel 이 저장한다.
        let didSelectPlace = PassthroughSubject<WishPlace, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case dismiss
    }

    struct State {
        var query: String = ""
        var candidates: [PlaceCandidate] = []
        var isResolving = false
    }

    struct Dependency {
        let placeSearchService: PlaceSearchServiceProtocol
        let logManager: LogManagerProtocol

        init(
            placeSearchService: PlaceSearchServiceProtocol = PlaceSearchService(),
            logManager: LogManagerProtocol = LogManager.shared
        ) {
            self.placeSearchService = placeSearchService
            self.logManager = logManager
        }
    }
}

/// 장소 검색 바텀시트 (GH-31 R-3).
final class PlaceSearchViewModel {
    let input = Input()
    let output = Output()
    var cancellables = Set<AnyCancellable>()
    private var state = State()
    private let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        bind()
    }

    private func bind() {
        input.inputQuery
            .withUnretained(self)
            .sink { (owner: PlaceSearchViewModel, query: String) in
                owner.search(query: query)
            }
            .store(in: &cancellables)

        input.didTapCandidate
            .withUnretained(self)
            .sink { (owner: PlaceSearchViewModel, index: Int) in
                owner.select(index: index)
            }
            .store(in: &cancellables)

        dependency.placeSearchService.candidates
            .withUnretained(self)
            .sink { (owner: PlaceSearchViewModel, result: Result<[PlaceCandidate], Error>) in
                owner.apply(result: result)
            }
            .store(in: &cancellables)
    }

    private func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        state.query = trimmed

        if trimmed.isEmpty {
            apply(candidates: [], isEmptyVisible: false)
        } else {
            dependency.placeSearchService.search(query: trimmed)
        }
    }

    private func apply(result: Result<[PlaceCandidate], Error>) {
        // 검색어를 지운 뒤 늦게 도착한 결과는 버린다
        guard !state.query.isEmpty else { return }

        switch result {
        case .success(let candidates):
            apply(candidates: candidates, isEmptyVisible: candidates.isEmpty)
        case .failure:
            apply(candidates: [], isEmptyVisible: true)
        }
    }

    private func apply(candidates: [PlaceCandidate], isEmptyVisible: Bool) {
        state.candidates = candidates
        output.candidates.send(candidates)
        output.isEmptyVisible.send(isEmptyVisible)
    }

    private func select(index: Int) {
        guard !state.isResolving, let candidate = state.candidates[safe: index] else { return }
        state.isResolving = true
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: output.screenName,
            objectType: .card,
            objectId: .selectPlace
        ))

        dependency.placeSearchService.resolve(candidate: candidate)
            .sink { [weak self] completion in
                guard let self else { return }
                state.isResolving = false
                if case .failure = completion {
                    apply(candidates: state.candidates, isEmptyVisible: true)
                }
            } receiveValue: { [weak self] place in
                self?.output.didSelectPlace.send(place)
                self?.output.route.send(.dismiss)
            }
            .store(in: &cancellables)
    }
}
