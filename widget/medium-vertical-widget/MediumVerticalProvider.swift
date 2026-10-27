import WidgetKit
import SwiftUI
import Intents

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
        let wishes = WidgetWishRepositoryImpl().fetchUnfinishedWishes()
            .sorted(by: Wish.deadlineOrder)
        return MediumVerticalEntry(date: Date(), wishes: Array(wishes.prefix(3)))
    }
}
