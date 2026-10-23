import MapKit

/// 핀이 모두 들어오는 지도 영역 (GH-31 R-6, GH-64 TC-1001)
enum PlaceMapCamera {
    /// 핀이 하나뿐일 때 보여줄 반경(m)
    static let singlePinDistance: CLLocationDistance = 3_000
    /// 위 개수 표시·아래 카드·화면 가장자리에 핀이 가리지 않게 넓히는 비율
    static let horizontalMargin: Double = 0.25
    static let topMargin: Double = 0.25
    static let bottomMargin: Double = 0.55

    /// 좌표가 없으면 nil, 하나면 반경 3km, 여럿이면 전부 담고 여백을 둔 영역
    static func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard let first = coordinates.first else { return nil }
        if coordinates.count == 1 {
            return MKCoordinateRegion(
                center: first,
                latitudinalMeters: singlePinDistance,
                longitudinalMeters: singlePinDistance
            )
        }
        return MKCoordinateRegion(fittingRect(for: coordinates))
    }

    static func fittingRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        let bounds = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            let point = MKMapPoint(coordinate)
            return rect.union(MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1))
        }
        let horizontal = bounds.width * horizontalMargin
        let top = bounds.height * topMargin
        let bottom = bounds.height * bottomMargin
        return MKMapRect(
            x: bounds.minX - horizontal,
            y: bounds.minY - top,
            width: bounds.width + horizontal * 2,
            height: bounds.height + top + bottom
        )
    }
}

extension Wish {
    var placeCoordinate: CLLocationCoordinate2D? {
        place.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
}
