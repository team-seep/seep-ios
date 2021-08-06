import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: ConfigurationIntent())
  }
  
  func getSnapshot(
    for configuration: ConfigurationIntent,
    in context: Context,
    completion: @escaping (SimpleEntry) -> ()
  ) {
    let entry = SimpleEntry(date: Date(), configuration: configuration)
    
    completion(entry)
  }
  
  func getTimeline(
    for configuration: ConfigurationIntent,
    in context: Context,
    completion: @escaping (Timeline<SimpleEntry>) -> Void
  ) {
    var entries: [SimpleEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(
        byAdding: .hour,
        value: hourOffset,
        to: currentDate
      )!
      let entry = SimpleEntry(date: entryDate, configuration: configuration)
      entries.append(entry)
    }
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}
