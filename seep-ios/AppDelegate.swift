import AppIntents
import os
import UIKit
import UserNotifications
import WidgetKit

import Firebase
import GRDB
import RealmSwift

/// Firebase·DB(App Group SQLite)·알림 델리게이트·앱 인텐트 의존성 (UI 없음). 진입점은 SwiftUI `SeepApp` (GH-64 A-1)
class AppDelegate: UIResponder, UIApplicationDelegate {
    private static let logger = Logger(subsystem: "macgongmon.seep-ios", category: "AppDelegate")
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DeviceKind.current = UIDevice.current.userInterfaceIdiom == .pad ? .pad : .phone
        self.initilizeFirebase()
        self.copyDefaultToAppGroup()
        self.setupDatabase()
        self.registerAppIntentDependencies()
        self.requestNotificationAuthorization()
        application.registerForRemoteNotifications()
        return true
    }
    
    /// 싶 적기 컨트롤·단축어(`OpenWriteIntent`)가 앱에 링크를 넘길 곳 (GH-49 R-11)
    private func registerAppIntentDependencies() {
        AppDependencyManager.shared.add(dependency: WriteDeepLinkOpener() as WriteDeepLinkOpening)
    }
    
    private func initilizeFirebase() {
        FirebaseApp.configure()
        
        // 연말 회고 노출 기간 등 Remote Config 최신 값을 받아 둔다 (GH-34 R-9).
        // 유닛 테스트가 콘솔 값에 흔들리지 않도록 테스트 호스트로 뜰 때는 받지 않는다
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        Task {
            let remoteConfig = RemoteConfigRepositoryImpl()
            await remoteConfig.fetchAndActivate()
            await reimportLegacyRealmIfRequested(token: remoteConfig.fetchLegacyRealmReimportToken())
        }
    }

    /// Remote Config 재이전 토큰이 새 값이면 원본 Realm 에서 빠진 위시를 다시 가져온다 (GH-96 R-3~R-8).
    /// DB 를 여는 `setupDatabase`보다 늦게 돌도록 Remote Config 를 받은 뒤에 부른다
    private func reimportLegacyRealmIfRequested(token: String) async {
        guard !token.isEmpty, AppDatabase.shared != nil else { return }
        let restoredCount = DatabaseMigrationFollowUp().reimportIfRequested(token: token)
        guard restoredCount > 0 else { return }
        await MainActor.run {
            WidgetCenter.shared.reloadAllTimelines()
            AppEnvironment.shared.router.wishesDidChange()
            AppEnvironment.shared.toastCenter.show(Strings.Home.MigrationNotice.reimportSuccessFormat(restoredCount))
        }
    }
    
    private func requestNotificationAuthorization() {
        let notificationCenter = UNUserNotificationCenter.current()
        let authOptions = UNAuthorizationOptions(arrayLiteral: .alert, .badge, .sound)
        
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                Self.logger.error("알림 권한 요청 실패: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    private func copyDefaultToAppGroup() {
        let fileManager = FileManager.default
        let originalPath = Realm.Configuration.defaultConfiguration.fileURL!
        let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.macgongmon.seep-ios")!
            .appendingPathComponent(Bundle.realmName)
        
        if fileManager.fileExists(atPath: originalPath.path) {
            do{
                try fileManager.replaceItemAt(appGroupURL, withItemAt: originalPath)
                Self.logger.info("Realm 파일을 App Group 으로 옮겼다")
                try fileManager.removeItem(at: originalPath)
            }
            catch{
                Self.logger.error("Realm 파일 이동 실패: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            Self.logger.debug("옮길 기존 Realm 파일 없음")
        }
    }
    
    /// App Group DB 를 열고(필요하면 Realm 에서 1회 이전) 이전 뒤 할 일을 한다 (GH-79)
    private func setupDatabase() {
        // 아주 예전 사용자의 Realm 을 App Group 으로 옮긴 뒤(copyDefaultToAppGroup) 연다. 여는 순간 1회 이전이 돈다
        guard AppDatabase.shared != nil else {
            Self.logger.error("DB 를 열지 못했다")
            return
        }
        DatabaseMigrationFollowUp().run()

        // 백그라운드로 가면 DB 잠금을 놓아 0xdead10cc 로 죽지 않게 하고, 돌아오면 다시 연다 (GH-79 R-11)
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            center.post(name: Database.suspendNotification, object: nil)
        }
        center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
            center.post(name: Database.resumeNotification, object: nil)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.list, .sound, .badge, .banner])
    }
}
