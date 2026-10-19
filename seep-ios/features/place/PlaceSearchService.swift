import Foundation
import Combine
import MapKit

/// 장소 검색 후보 한 줄 (이름 + 주소). `MKLocalSearchCompletion` 을 ViewModel 이 모르게 감싼다.
struct PlaceCandidate: Hashable {
    let id: String
    let title: String
    let subtitle: String
}

enum PlaceSearchError: Error {
    case notFound
}

/// Apple 지도 검색 (GH-31 R-3). 서버·API 키·위치 권한 없이 동작한다.
protocol PlaceSearchServiceProtocol: AnyObject {
    /// 검색어가 바뀔 때마다 후보 목록(또는 실패)을 보낸다
    var candidates: AnyPublisher<Result<[PlaceCandidate], Error>, Never> { get }

    func search(query: String)

    /// 후보의 좌표·주소를 받아 장소로 만든다
    func resolve(candidate: PlaceCandidate) -> AnyPublisher<WishPlace, Error>
}

final class PlaceSearchService: NSObject, PlaceSearchServiceProtocol {
    private let completer: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.pointOfInterest, .address]
        return completer
    }()
    private let candidatesSubject = PassthroughSubject<Result<[PlaceCandidate], Error>, Never>()
    private var completions: [String: MKLocalSearchCompletion] = [:]

    var candidates: AnyPublisher<Result<[PlaceCandidate], Error>, Never> {
        candidatesSubject.eraseToAnyPublisher()
    }

    override init() {
        super.init()
        completer.delegate = self
    }

    func search(query: String) {
        completer.queryFragment = query
    }

    func resolve(candidate: PlaceCandidate) -> AnyPublisher<WishPlace, Error> {
        guard let completion = completions[candidate.id] else {
            return Fail(error: PlaceSearchError.notFound).eraseToAnyPublisher()
        }

        return Future<WishPlace, Error> { promise in
            let search = MKLocalSearch(request: MKLocalSearch.Request(completion: completion))
            search.start { response, error in
                guard let mapItem = response?.mapItems.first else {
                    promise(.failure(error ?? PlaceSearchError.notFound))
                    return
                }

                let coordinate = Self.coordinate(of: mapItem)
                promise(.success(WishPlace(
                    name: candidate.title,
                    address: candidate.subtitle.isEmpty ? (mapItem.name ?? "") : candidate.subtitle,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )))
            }
        }
        .eraseToAnyPublisher()
    }

    private static func coordinate(of mapItem: MKMapItem) -> CLLocationCoordinate2D {
        if #available(iOS 26.0, *) {
            return mapItem.location.coordinate
        } else {
            return mapItem.placemark.coordinate
        }
    }
}

extension PlaceSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var completions: [String: MKLocalSearchCompletion] = [:]
        let candidates = completer.results.enumerated().map { index, completion in
            let id = "\(index)-\(completion.title)-\(completion.subtitle)"
            completions[id] = completion
            return PlaceCandidate(id: id, title: completion.title, subtitle: completion.subtitle)
        }
        self.completions = completions
        candidatesSubject.send(.success(candidates))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = [:]
        candidatesSubject.send(.failure(error))
    }
}
