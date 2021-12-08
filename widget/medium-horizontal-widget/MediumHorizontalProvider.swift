import WidgetKit
import SwiftUI
import Intents

import RealmSwift

struct MediumHorizontalProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> MediumHorizontalEntry {
        return self.generateEntry()
    }
    
    func getSnapshot(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (MediumHorizontalEntry) -> ()
    ) {
        completion(self.generateEntry())
    }
    
    func getTimeline(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (Timeline<MediumHorizontalEntry>) -> Void
    ) {
        let timeline = Timeline(entries: [self.generateEntry()], policy: .atEnd)
        
        completion(timeline)
    }
    
    private func generateEntry() -> MediumHorizontalEntry {
        let realmPath = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.macgongmon.seep-ios")?
            .appendingPathComponent(Bundle.realmName)
        let realmConfig = Realm.Configuration(fileURL: realmPath)
        
        if let realm = try? Realm(configuration: realmConfig) {
            let wishes = realm.objects(Wish.self)
                .map { $0 }
                .filter { !$0.isSuccess }
                .sorted(by: Wish.deadlineOrder)
            let wishSlice = wishes.count < 3 ? wishes : Array(wishes[..<3])
            let entry = MediumHorizontalEntry(date: Date(), wishes: wishSlice)
            
            return entry
        } else {
            return MediumHorizontalEntry.preview
        }
    }
}
