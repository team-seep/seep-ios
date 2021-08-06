import WidgetKit
import SwiftUI
import Intents

struct SmallProvider: TimelineProvider {
  func placeholder(in context: Context) -> SmallEntry {
    SmallEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SmallEntry) -> Void) {
    let date = Date()
    let entry = SmallEntry(date: date)
    
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<SmallEntry>) -> Void) {
    let date = Date()
    let entry = SmallEntry(date: date)
    let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
    
    completion(timeline)
  }
}
