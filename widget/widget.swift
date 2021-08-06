import WidgetKit
import SwiftUI
import Intents

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationIntent
}

@main
struct widgets: WidgetBundle {
  let kind: String = "widget"
  
  @WidgetBundleBuilder
  var body: some Widget {
    SmallWidget()
  }
}
