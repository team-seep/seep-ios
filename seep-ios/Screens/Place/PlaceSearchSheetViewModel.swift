import Foundation
import Combine
import Observation

extension PlaceSearchSheetViewModel {
    enum Action: Equatable {
        case inputQuery(String)
        case tapCandidate(index: Int)
        case routeHandled
    }

    struct State: Equatable {
        var query = ""
        var candidates: [PlaceCandidate] = []
        /// 검색어가 있는데 후보가 없거나 검색이 실패했을 때 "찾는 장소가 없어요" (GH-31 R-3)
        var isEmptyVisible = false
        var isResolving = false
    }

    enum Route: Equatable {
        /// 후보를 골라 좌표까지 받은 장소. 시트를 닫고 고른 곳(작성·상세 장소 섹션)에 넘긴다
        case selected(WishPlace)
    }

    struct Dependency {
        let placeSearchService: PlaceSearchServiceProtocol
        let logManager: LogManagerProtocol
        /// 입력이 멈춘 뒤 검색을 보내기까지 기다리는 시간 (GH-64 TC-1003)
        let debounce: TimeInterval

        init(
            placeSearchService: PlaceSearchServiceProtocol = PlaceSearchService(),
            logManager: LogManagerProtocol = LogManager.shared,
            debounce: TimeInterval = 0.3
        ) {
            self.placeSearchService = placeSearchService
            self.logManager = logManager
            self.debounce = debounce
        }
    }
}

/// "어디로 가고 싶어요?" 장소 검색 시트 (GH-31 R-3, GH-64 TC-1003).
/// 작성·상세의 장소 섹션(P2)이 `.seepSheet`로 띄운다
@Observable
final class PlaceSearchSheetViewModel {
    let screenName: ScreenName = .placeSearchBottomSheet
    private(set) var state = State()
    private(set) var route: Route?

    private let dependency: Dependency
    @ObservationIgnored private var pendingSearch: DispatchWorkItem?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        dependency.placeSearchService.candidates
            .sink { [weak self] result in
                self?.apply(result: result)
            }
            .store(in: &cancellables)
    }

    func send(_ action: Action) {
        switch action {
        case .inputQuery(let query):
            input(query: query)
        case .tapCandidate(let index):
            select(index: index)
        case .routeHandled:
            route = nil
        }
    }

    private func input(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != state.query else { return }
        state.query = trimmed
        pendingSearch?.cancel()

        guard !trimmed.isEmpty else {
            apply(candidates: [], isEmptyVisible: false)
            return
        }
        // 타이핑 중에는 검색하지 않고, 입력이 멈추면 마지막 검색어로 한 번만 보낸다
        let search = DispatchWorkItem { [weak self] in
            self?.dependency.placeSearchService.search(query: trimmed)
        }
        pendingSearch = search
        DispatchQueue.main.asyncAfter(deadline: .now() + dependency.debounce, execute: search)
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
        state.isEmptyVisible = isEmptyVisible
    }

    private func select(index: Int) {
        guard !state.isResolving, let candidate = state.candidates[safe: index] else { return }
        state.isResolving = true
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .card,
            objectId: .selectPlace
        ))

        dependency.placeSearchService.resolve(candidate: candidate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                state.isResolving = false
                if case .failure = completion {
                    apply(candidates: state.candidates, isEmptyVisible: true)
                }
            } receiveValue: { [weak self] place in
                self?.route = .selected(place)
            }
            .store(in: &cancellables)
    }
}
