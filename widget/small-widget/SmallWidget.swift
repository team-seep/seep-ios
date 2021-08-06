import WidgetKit
import SwiftUI
import Intents

struct SmallWidget: Widget {
  let kind: String = "smallWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: self.kind,
      provider: SmallProvider()
    ) { entry in
      SmallEntryView()
    }
    .configurationDisplayName("빠르게 등록하기")
    .description("누구보다 빠르게 하고싶은 것을 등록해보는건 어때요?")
    .supportedFamilies([.systemSmall])
  }
}
