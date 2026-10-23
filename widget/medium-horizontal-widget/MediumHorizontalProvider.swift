import WidgetKit
import SwiftUI
import Intents

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
        let wishes = WidgetWishRepositoryImpl().fetchUnfinishedWishes()
            .sorted(by: Wish.deadlineOrder)
        return MediumHorizontalEntry(date: Date(), wishes: Array(wishes.prefix(3)))
    }
}
