import Foundation
import Network

/// 지금 인터넷에 연결돼 있는지 (GH-93 R-29: 오프라인이면 계정 삭제를 막는다)
protocol NetworkStatusProviding {
    var isConnected: Bool { get }
}

final class NetworkMonitor: NetworkStatusProviding {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let lock = NSLock()
    private var status: NWPath.Status = .satisfied

    var isConnected: Bool {
        lock.withLock { status == .satisfied }
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            lock.withLock { self.status = path.status }
        }
        monitor.start(queue: DispatchQueue(label: "macgongmon.seep.network-monitor", qos: .utility))
    }
}
