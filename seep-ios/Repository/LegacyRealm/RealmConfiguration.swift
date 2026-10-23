import Foundation

import RealmSwift

/// GH-79 이전에 쓰던 App Group Realm. 이제 위시는 `AppDatabase`(GRDB)에 있고, 이 설정은 1회 이전(`LegacyRealmImporter`)에서만 연다.
/// Realm 파일·RealmSwift 의존성은 이전 실패율을 본 뒤 후속 이슈에서 지운다 (GH-79 R-21).
enum LegacyRealmConfiguration {
    static func make(fileURL: URL?) -> Realm.Configuration {
        var config = Realm.Configuration()
        config.fileURL = fileURL
        // 앱·위젯·테스트 바이너리에 다른 Object 가 있어도 이 네 개만 연다
        config.objectTypes = [WishDTO.self, NotificationDTO.self, WishStepDTO.self, SavingDTO.self]
        config.schemaVersion = 7
        config.migrationBlock = migrate
        return config
    }

    /// App Group 의 Realm 파일. 파일이 없으면(신규 설치) nil
    static var sharedFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppDatabase.appGroupIdentifier)?
            .appendingPathComponent(Bundle.realmName)
    }

    // schemaVersion 7 까지의 Realm 마이그레이션. GH-79 전까지 AppDelegate 에 있던 것을 옮겼다
    private static func migrate(_ migration: Migration, _ oldSchemaVersion: UInt64) {
        if oldSchemaVersion < 3 {
            // 예전 "Wish" 객체를 WishDTO 로 옮긴다. 비어 있는 값은 기본값으로 채워 위시를 버리지 않는다 (GH-79 R-18)
            migration.enumerateObjects(ofType: "Wish") { oldObject, _ in
                guard let oldObject else { return }
                let wishDTO: MigrationObject = migration.create("WishDTO")

                wishDTO["_id"] = (oldObject["_id"] as? ObjectId)?.stringValue
                    ?? (oldObject["_id"] as? String)
                    ?? UUID().uuidString
                wishDTO["emoji"] = oldObject["emoji"] as? String ?? ""
                wishDTO["category"] = oldObject["category"] as? String ?? Category.wantToDo.rawValue
                wishDTO["title"] = oldObject["title"] as? String ?? ""
                wishDTO["date"] = oldObject["date"] as? Date
                wishDTO["finishDate"] = oldObject["finishDate"] as? Date
                if oldObject["isPushEnable"] as? Bool == true {
                    wishDTO["notifications"] = [
                        NotificationDTO(seepNotification: SeepNotification(type: .dayAgo)),
                        NotificationDTO(seepNotification: SeepNotification(type: .twoDayAgo))
                    ]
                } else {
                    wishDTO["notifications"] = []
                }
                wishDTO["memo"] = oldObject["memo"] as? String ?? ""
                wishDTO["hashtag"] = oldObject["hashtag"] as? String ?? ""
                wishDTO["isSuccess"] = oldObject["isSuccess"] as? Bool ?? false
                wishDTO["createdAt"] = oldObject["createdAt"] as? Date ?? Date()
            }
            migration.deleteData(forType: "Wish")
        }

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

        // 7: pinnedAt(GH-33)·link(GH-29)·lastCheckedAt(GH-30)·장소(GH-31)·photoFileName(GH-36) 추가 — 기존 위시는 모두 빈 값
        if oldSchemaVersion < 7 {
            migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
                newObject?["pinnedAt"] = nil
                newObject?["link"] = ""
                newObject?["lastCheckedAt"] = nil
                newObject?["placeName"] = ""
                newObject?["placeAddress"] = ""
                newObject?["latitude"] = 0.0
                newObject?["longitude"] = 0.0
                newObject?["photoFileName"] = ""
            }
        }
    }
}
