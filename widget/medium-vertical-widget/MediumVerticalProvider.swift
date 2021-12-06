import WidgetKit
import SwiftUI
import Intents

import RealmSwift

struct MediumVerticalProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> MediumVerticalEntry {
        return self.generateEntry()
    }
    
    func getSnapshot(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (MediumVerticalEntry) -> ()
    ) {
        completion(self.generateEntry())
    }
    
    func getTimeline(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (Timeline<MediumVerticalEntry>) -> Void
    ) {
        let timeline = Timeline(entries: [self.generateEntry()], policy: .atEnd)
        
        completion(timeline)
    }
    
    private func generateEntry() -> MediumVerticalEntry {
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
            let entry = MediumVerticalEntry(date: Date(), wishes: wishSlice)
            
            return entry
        } else {
            return MediumVerticalEntry.preview
        }
    }
}
