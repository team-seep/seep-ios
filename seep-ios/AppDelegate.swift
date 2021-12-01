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
  
  private func initilizeFirebase() {
    FirebaseApp.configure()
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
      .appendingPathComponent("default.realm")
    
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
      .appendingPathComponent("default.realm")

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
