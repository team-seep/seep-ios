import CoreLocation
import Foundation
import os
import UserNotifications

/// 위치 권한을 화면·스케줄러가 쓰는 값으로 줄인 것 (GH-126 R-3). 위치는 "앱을 사용하는 동안"이면 충분하다
enum LocationAuthorization: Equatable {
    /// 앱 사용 중 허용 또는 항상 허용
    case authorized
    /// 거부·제한(자녀 보호 등)
    case denied
    /// 아직 묻지 않음
    case notDetermined
}

/// 근처 알림이 닿는 시스템(알림 센터·위치 권한). 유닛 테스트는 목으로 바꾼다 (GH-126)
protocol NearbyAlertCenter: AnyObject {
    func notificationAuthorization() async -> NotificationAuthorization
    /// 미결정일 때 시스템 팝업으로 묻고 결과를 돌려준다
    func requestNotificationAuthorization() async -> NotificationAuthorization
    func locationAuthorization() async -> LocationAuthorization
    /// 미결정일 때 "앱을 사용하는 동안" 팝업으로 묻고 결과를 돌려준다
    func requestLocationAuthorization() async -> LocationAuthorization
    /// 대기 중인 근처 알림(`nearby-` 식별자)만
    func pendingNearbyIdentifiers() async -> [String]
    /// 같은 식별자가 있으면 덮어쓴다
    func add(_ request: NearbyAlertRequest)
    func remove(identifiers: [String])
}

/// `UNUserNotificationCenter` + `CLLocationManager`. 위치 판정은 iOS 가 기기 안에서 하고, 앱은 좌표를 어디에도 보내지 않는다 (R-4)
final class SystemNearbyAlertCenter: NearbyAlertCenter {
    private static let logger = Logger(subsystem: "macgongmon.seep-ios", category: "NearbyAlert")

    private var notificationCenter: UNUserNotificationCenter { .current() }
    /// 위치 권한 팝업이 떠 있는 동안 델리게이트를 붙잡아 둔다
    private var locationRequester: LocationAuthorizationRequester?

    func notificationAuthorization() async -> NotificationAuthorization {
        let settings = await notificationCenter.notificationSettings()
        return Self.notificationAuthorization(settings.authorizationStatus)
    }

    func requestNotificationAuthorization() async -> NotificationAuthorization {
        do {
            _ = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            Self.logger.error("알림 권한 요청 실패: \(error.localizedDescription, privacy: .public)")
        }
        return await notificationAuthorization()
    }

    func locationAuthorization() async -> LocationAuthorization {
        await MainActor.run {
            let manager = CLLocationManager()
            return Self.locationAuthorization(manager.authorizationStatus, accuracy: manager.accuracyAuthorization)
        }
    }

    func requestLocationAuthorization() async -> LocationAuthorization {
        await withCheckedContinuation { continuation in
            // CLLocationManager 델리게이트는 만든 스레드의 런루프로 온다. 메인에서 만든다
            DispatchQueue.main.async { [self] in
                let requester = LocationAuthorizationRequester { [weak self] status in
                    self?.locationRequester = nil
                    continuation.resume(returning: status)
                }
                locationRequester = requester
                requester.start()
            }
        }
    }

    func pendingNearbyIdentifiers() async -> [String] {
        await notificationCenter.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(NearbyAlertRequest.identifierPrefix) }
    }

    func add(_ request: NearbyAlertRequest) {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude),
            radius: request.radius,
            identifier: request.identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        // 한 번 울리면 사라진다. 앱이 활성화될 때 다시 건다 (R-5)
        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)

        notificationCenter.add(UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)) { error in
            if let error {
                Self.logger.error("근처 알림 예약 실패: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func remove(identifiers: [String]) {
        guard !identifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func notificationAuthorization(_ status: UNAuthorizationStatus) -> NotificationAuthorization {
        switch status {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    /// 정확한 위치를 끈(대략적 위치) 허용은 거부로 본다. iOS 는 대략적 위치에서 지역 감시를 하지 않아
    /// 토글만 켜지고 알림은 오지 않는다. 거부로 돌려 [설정 열기] 알럿에서 정확한 위치를 켜게 한다
    static func locationAuthorization(_ status: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization) -> LocationAuthorization {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return accuracy == .fullAccuracy ? .authorized : .denied
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}

/// "앱을 사용하는 동안" 위치 권한을 한 번 묻고, 사용자가 고르면 결과를 넘긴다
private final class LocationAuthorizationRequester: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((LocationAuthorization) -> Void)?

    init(completion: @escaping (LocationAuthorization) -> Void) {
        self.completion = completion
        super.init()
        manager.delegate = self
    }

    func start() {
        let current = SystemNearbyAlertCenter.locationAuthorization(manager.authorizationStatus, accuracy: manager.accuracyAuthorization)
        guard current == .notDetermined else {
            finish(current)
            return
        }
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 델리게이트를 붙이자마자 지금 상태(미결정)로 한 번 불린다. 사용자가 고를 때까지 기다린다
        let status = SystemNearbyAlertCenter.locationAuthorization(manager.authorizationStatus, accuracy: manager.accuracyAuthorization)
        guard status != .notDetermined else { return }
        finish(status)
    }

    private func finish(_ status: LocationAuthorization) {
        completion?(status)
        completion = nil
    }
}
