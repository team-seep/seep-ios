import WidgetKit
import SwiftUI
import Intents

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
        
        let wishCount = WidgetWishRepositoryImpl().fetchUnfinishedCount(category: randomCategory)
        return SmallRemainEntry(date: date, category: randomCategory, count: wishCount)
    }
}
