import WidgetKit
import SwiftUI
import Intents

import RealmSwift

struct MediumProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> MediumEntry {
        return self.generateEntry()
    }
    
    func getSnapshot(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (MediumEntry) -> ()
    ) {
        completion(self.generateEntry())
    }
    
    func getTimeline(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (Timeline<MediumEntry>) -> Void
    ) {
        let timeline = Timeline(entries: [self.generateEntry()], policy: .atEnd)
        
        completion(timeline)
    }
    
    private func generateEntry() -> MediumEntry {
        let realmPath = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.macgongmon.seep-ios")?
            .appendingPathComponent(Bundle.realmName)
        let realmConfig = Realm.Configuration(fileURL: realmPath)
        
        if let realm = try? Realm(configuration: realmConfig) {
            let wishes = realm.objects(Wish.self).map { $0 }.sorted(by: Wish.deadlineOrder)
            let wishSlice = wishes.count < 3 ? wishes : Array(wishes[..<3])
            let entry = MediumEntry(date: Date(), wishes: wishSlice)
            
            return entry
        } else {
            return MediumEntry.preview
        }
    }
}
