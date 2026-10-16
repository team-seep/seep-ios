import Foundation
import OSLog

import FirebaseAnalytics

protocol LogManagerProtocol {
    func sendPageView(screen: ScreenName, type: AnyObject.Type)

    func sendPageView(screen: ScreenName, type: AnyObject.Type, extraParameters: [ParameterName: Any]?)

    func sendEvent(event: LogEventType)
}

/// Firebase Analytics 전송. Debug 빌드는 Dev Firebase 프로젝트로 가고(GoogleService-Info-Dev), 콘솔에 디버그 로그를 남긴다.
final class LogManager: LogManagerProtocol {
    static let shared = LogManager()

    private var isEnableDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    func sendPageView(screen: ScreenName, type: AnyObject.Type) {
        sendPageView(screen: screen, type: type, extraParameters: nil)
    }

    func sendPageView(screen: ScreenName, type: AnyObject.Type, extraParameters: [ParameterName: Any]?) {
        var parameters: [String: Any] = [
            AnalyticsParameterScreenName: screen.rawValue,
            AnalyticsParameterScreenClass: NSStringFromClass(type.self)
        ]
        extraParameters?.forEach { key, value in
            parameters[key.rawValue] = value
        }

        Analytics.logEvent(AnalyticsEventScreenView, parameters: parameters)

        if isEnableDebug {
            debugLog(kind: "PageView", name: screen.rawValue, parameters: parameters)
        }
    }

    func sendEvent(event: LogEventType) {
        Analytics.logEvent(event.name.rawValue, parameters: event.parameters)

        if isEnableDebug {
            debugLog(kind: "Event", name: event.name.rawValue, parameters: event.parameters)
        }
    }

    private func debugLog(kind: String, name: String, parameters: [String: Any]) {
        let message: StaticString = """
        💙 [LogManager]: %{PUBLIC}@
            => name: %{PUBLIC}@
            => parameter: %{PUBLIC}@
        """
        let parameterString = parameters
            .sorted { $0.key < $1.key }
            .map { "\n\t\($0.key): \($0.value)," }
            .joined()

        os_log(.debug, message, kind, name, parameterString)
    }
}
