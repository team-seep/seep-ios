import Combine

@testable import seep_ios_dev

/// PlaceSearchServiceProtocol 스텁. 검색어를 기록하고, 후보는 테스트가 `sendCandidates` 로 직접 흘린다.
final class MockPlaceSearchService: PlaceSearchServiceProtocol {
    private let candidatesSubject = PassthroughSubject<Result<[PlaceCandidate], Error>, Never>()
    private(set) var searchedQueries: [String] = []
    private(set) var resolvedCandidates: [PlaceCandidate] = []
    var resolveResult: Result<WishPlace, Error> = .failure(PlaceSearchError.notFound)

    var candidates: AnyPublisher<Result<[PlaceCandidate], Error>, Never> {
        candidatesSubject.eraseToAnyPublisher()
    }

    func search(query: String) {
        searchedQueries.append(query)
    }

    func resolve(candidate: PlaceCandidate) -> AnyPublisher<WishPlace, Error> {
        resolvedCandidates.append(candidate)
        return resolveResult.publisher.eraseToAnyPublisher()
    }

    func sendCandidates(_ result: Result<[PlaceCandidate], Error>) {
        candidatesSubject.send(result)
    }
}
