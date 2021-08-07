import WidgetKit
import SwiftUI
import Intents

struct MediumProvider: IntentTimelineProvider {
  func placeholder(in context: Context) -> MediumEntry {
    MediumEntry(date: Date(), configuration: ConfigurationIntent())
  }
  
  func getSnapshot(
    for configuration: ConfigurationIntent,
    in context: Context,
    completion: @escaping (MediumEntry) -> ()
  ) {
    let entry = MediumEntry(date: Date(), configuration: configuration)
    
    completion(entry)
  }
  
  func getTimeline(
    for configuration: ConfigurationIntent,
    in context: Context,
    completion: @escaping (Timeline<MediumEntry>) -> Void
  ) {
    var entries: [MediumEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(
        byAdding: .hour,
        value: hourOffset,
        to: currentDate
      )!
      let entry = MediumEntry(date: entryDate, configuration: configuration)
      entries.append(entry)
    }
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}
