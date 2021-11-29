import WidgetKit
import SwiftUI
import Intents

struct SmallWriteProvider: TimelineProvider {
  func placeholder(in context: Context) -> SmallWriteEntry {
    SmallWriteEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SmallWriteEntry) -> Void) {
    let date = Date()
    let entry = SmallWriteEntry(date: date)
    
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<SmallWriteEntry>) -> Void) {
    let date = Date()
    let entry = SmallWriteEntry(date: date)
    let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
    
    completion(timeline)
  }
}
