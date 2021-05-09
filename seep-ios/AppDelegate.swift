import UIKit
import Firebase
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    self.initilizeFirebase()
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
