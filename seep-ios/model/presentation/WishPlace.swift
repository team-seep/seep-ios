import Foundation

/// 가고 싶은 곳에 붙인 실제 장소 (GH-31). 좌표는 MapKit 검색 결과를 그대로 저장한다.
struct WishPlace: Equatable, Hashable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    /// DB 에 저장된 값에서 만든다. 이름이 비어 있으면 장소 없음(nil)이다.
    static func stored(name: String, address: String, latitude: Double, longitude: Double) -> WishPlace? {
        guard !name.isEmpty else { return nil }
        return WishPlace(name: name, address: address, latitude: latitude, longitude: longitude)
    }
}
