import WidgetKit
import SwiftUI
import Intents

struct SmallRemainProvider: TimelineProvider {
  func placeholder(in context: Context) -> SmallRemainEntry {
    SmallRemainEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SmallRemainEntry) -> Void) {
    let date = Date()
    let entry = SmallRemainEntry(date: date)
    
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<SmallRemainEntry>) -> Void) {
    let date = Date()
    let entry = SmallRemainEntry(date: date)
    let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
    
    completion(timeline)
  }
}
