import WidgetKit
import SwiftUI
import Intents
import RealmSwift

struct SmallRemainProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallRemainEntry {
        return self.generateRandomCategoryCount()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SmallRemainEntry) -> Void) {
        completion(self.generateRandomCategoryCount())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallRemainEntry>) -> Void) {
        let date = Date()
        let entry = self.generateRandomCategoryCount()
        let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
    
    private func generateRandomCategoryCount() -> SmallRemainEntry {
        let date = Date()
        let randomCategory: Category = [
            Category.wantToDo,
            Category.wantToGet,
            Category.wantToGo
        ].randomElement() ?? .wantToDo
        
        let realmPath = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.macgongmon.seep-ios")?
            .appendingPathComponent(Bundle.realmName)
        var realmConfig = Realm.Configuration(fileURL: realmPath)
        realmConfig.schemaVersion = 2
        
        if let realm = try? Realm(configuration: realmConfig) {
            let searchTask = realm.objects(WishDTO.self)
                .filter { ($0.isSuccess == false) && ($0.category == randomCategory.rawValue) }
            let wishCount = searchTask.map { $0 }.count
            
            let entry = SmallRemainEntry(date: date, category: randomCategory, count: wishCount)
            
            return entry
        } else {
            return SmallRemainEntry(date: date, category: randomCategory, count: 100)
        }
    }
}
