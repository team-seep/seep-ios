import Foundation

@testable import seep_ios

/// 근처 알림이 닿는 시스템(알림 센터·위치 권한) 목 (GH-126). 대기 중인 알림을 메모리에 들고, 권한 팝업 순서를 기록한다.
/// `NotificationManager`가 다른 스레드의 Task 에서 예약하므로 기록은 잠금으로 감싼다
final class MockNearbyAlertCenter: NearbyAlertCenter, @unchecked Sendable {
    var notificationStatus: NotificationAuthorization = .authorized
    var locationStatus: LocationAuthorization = .authorized
    /// 팝업에서 사용자가 고를 값
    var notificationAnswer: NotificationAuthorization = .authorized
    var locationAnswer: LocationAuthorization = .authorized

    private let lock = NSLock()
    private var _requestedPermissions: [String] = []
    private var _pending: [String: NearbyAlertRequest] = [:]
    private var _addedRequests: [NearbyAlertRequest] = []
    private var _removedIdentifiers: [String] = []

    /// 띄운 권한 팝업 순서 ("notification", "location")
    var requestedPermissions: [String] { lock.withLock { _requestedPermissions } }
    /// 대기 중인 근처 알림 (식별자 → 요청)
    var pending: [String: NearbyAlertRequest] { lock.withLock { _pending } }
    var addedRequests: [NearbyAlertRequest] { lock.withLock { _addedRequests } }
    var removedIdentifiers: [String] { lock.withLock { _removedIdentifiers } }

    func notificationAuthorization() async -> NotificationAuthorization {
        notificationStatus
    }

    func requestNotificationAuthorization() async -> NotificationAuthorization {
        lock.withLock { _requestedPermissions.append("notification") }
        notificationStatus = notificationAnswer
        return notificationStatus
    }

    func locationAuthorization() async -> LocationAuthorization {
        locationStatus
    }

    func requestLocationAuthorization() async -> LocationAuthorization {
        lock.withLock { _requestedPermissions.append("location") }
        locationStatus = locationAnswer
        return locationStatus
    }

    func pendingNearbyIdentifiers() async -> [String] {
        Array(pending.keys)
    }

    func add(_ request: NearbyAlertRequest) {
        lock.withLock {
            _addedRequests.append(request)
            _pending[request.identifier] = request
        }
    }

    func remove(identifiers: [String]) {
        lock.withLock {
            _removedIdentifiers.append(contentsOf: identifiers)
            identifiers.forEach { _pending[$0] = nil }
        }
    }

    /// 이미 걸려 있던 알림(이전 실행에서 건 것)
    func seedPending(_ request: NearbyAlertRequest) {
        lock.withLock { _pending[request.identifier] = request }
    }
}
