import Foundation

import RealmSwift

/// 앱·위젯이 같이 여는 App Group Realm 설정 (GH-48 R-6).
/// 경로·schemaVersion 을 한 곳에 둬서 위젯 인텐트가 쓰는 Realm 과 앱이 쓰는 Realm 이 어긋나지 않게 한다.
/// 마이그레이션 블록은 앱(AppDelegate)만 붙인다 — 위젯은 앱이 먼저 마이그레이션한 파일을 연다.
enum RealmConfiguration {
    static let appGroupIdentifier = "group.macgongmon.seep-ios"

    static var shared: Realm.Configuration {
        var config = Realm.Configuration()
        config.fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(Bundle.realmName)
        // R4: Realm 모델을 바꾸면 이 값을 올린다 (scripts/check-realm-schema.sh 가 앱·위젯 값과 같은지 본다)
        config.schemaVersion = 7
        return config
    }
}
