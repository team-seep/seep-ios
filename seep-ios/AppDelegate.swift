import AppIntents
import UIKit
import UserNotifications

import Firebase
import RealmSwift


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.initilizeFirebase()
        self.copyDefaultToAppGroup()
        self.setupRealmConfig()
        self.registerAppIntentDependencies()
        self.requestNotificationAuthorization()
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
    
    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        
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
            await RemoteConfigRepositoryImpl().fetchAndActivate()
        }
    }
    
    private func requestNotificationAuthorization() {
        let notificationCenter = UNUserNotificationCenter.current()
        let authOptions = UNAuthorizationOptions(arrayLiteral: .alert, .badge, .sound)
        
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print("Error: \(error)")
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
                print("Successfully replaced DB file")
                try fileManager.removeItem(at: originalPath)
            }
            catch{
                print("Error info: \(error)")
            }
        } else {
            print("File is not exist on original path")
        }
    }
    
    private func setupRealmConfig() {
        var config = Realm.Configuration()
        
        config.fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.macgongmon.seep-ios")?
            .appendingPathComponent(Bundle.realmName)
        config.schemaVersion = 7
        
        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 3 {
                migration.enumerateObjects(ofType: "Wish") { oldObject, newObject in
                    guard let oldObject = oldObject,
                          let id = oldObject["_id"] as? ObjectId,
                          let emoji = oldObject["emoji"] as? String,
                          let category = oldObject["category"] as? String,
                          let title = oldObject["title"] as? String,
                          let date = oldObject["date"] as? Date,
                          let isPushEnable = oldObject["isPushEnable"] as? Bool,
                          let memo = oldObject["memo"] as? String,
                          let hashtag = oldObject["hashtag"] as? String,
                          let isSuccess = oldObject["isSuccess"] as? Bool,
                          let createdAt = oldObject["createdAt"] as? Date else {
                        return print("some field is nil")
                    }
                    
                    let wishDTO: MigrationObject = migration.create("WishDTO")
                    
                    wishDTO["_id"] = id.stringValue
                    wishDTO["emoji"] = emoji
                    wishDTO["category"] = category
                    wishDTO["title"] = title
                    wishDTO["date"] = date
                    wishDTO["finishDate"] = oldObject["finishDate"] as? Date
                    if isPushEnable {
                        wishDTO["notifications"] = [
                            NotificationDTO(seepNotification: SeepNotification(type: .dayAgo)),
                            NotificationDTO(seepNotification: SeepNotification(type: .twoDayAgo))
                        ]
                    } else {
                        wishDTO["notifications"] = []
                    }
                    wishDTO["memo"] = memo
                    wishDTO["hashtag"] = hashtag
                    wishDTO["isSuccess"] = isSuccess
                    wishDTO["createdAt"] = createdAt
                }
            }
            migration.deleteData(forType: "Wish")
            
            // 4: WishDTO.steps(List<WishStepDTO>) 추가 — 기존 위시는 단계 0개로 시작한다
            if oldSchemaVersion < 4 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["steps"] = [WishStepDTO]()
                }
            }
            
            // 5: WishDTO.targetAmount(Int) + savings(List<SavingDTO>) 추가 — 기존 위시는 목표 금액 0, 기록 없음 (GH-16 R-8)
            if oldSchemaVersion < 5 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["targetAmount"] = 0
                    newObject?["savings"] = [SavingDTO]()
                }
            }
            
            // 6: WishDTO.finishNote(String) 추가 — 기존 위시는 소감 없음(빈 문자열) (GH-25 R-4)
            if oldSchemaVersion < 6 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["finishNote"] = ""
                }
            }
            
            // 7: WishDTO.pinnedAt(Date?) 추가 — 기존 위시는 모두 고정 아님 (GH-33 R-1)
            if oldSchemaVersion < 7 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["pinnedAt"] = nil
                }
            }
            
            // 7: WishDTO.link(String) 추가 — 기존 위시는 링크 없음(빈 문자열) (GH-29 R-7)
            if oldSchemaVersion < 7 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["link"] = ""
                }
            }
            
            // 7: WishDTO.lastCheckedAt(Date?) 추가 — 기존 위시는 점검한 적 없음(nil), 만든 날을 기준으로 잠든 위시를 판정한다 (GH-30 R-1)
            if oldSchemaVersion < 7 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["lastCheckedAt"] = nil
                }
            }
            
            // 7: WishDTO.placeName·placeAddress(String) + latitude·longitude(Double) 추가 — 기존 위시는 장소 없음 (GH-31)
            if oldSchemaVersion < 7 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["placeName"] = ""
                    newObject?["placeAddress"] = ""
                    newObject?["latitude"] = 0.0
                    newObject?["longitude"] = 0.0
                }
            }
            
            // 7: WishDTO.photoFileName(String) 추가 — 기존 위시는 사진 없음(빈 문자열) (GH-36 R-9)
            if oldSchemaVersion < 7 {
                migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                    newObject?["photoFileName"] = ""
                }
            }
        }
        
        Realm.Configuration.defaultConfiguration = config
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
