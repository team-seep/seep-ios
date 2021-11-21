import WidgetKit
import SwiftUI
import Intents

struct SmallWriteWidget: Widget {
  
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "\(SmallWriteWidget.self)",
      provider: SmallWriteProvider()
    ) { entry in
      SmallWriteEntryView(categoryData: SmallWriteWidgetData(category: entry.category))
    }
    .configurationDisplayName("빠르게 등록하기")
    .description("누구보다 빠르게 나의 위시 리스트를 등록해보는건 어때요?")
    .supportedFamilies([.systemSmall])
  }
}
