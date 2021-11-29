import WidgetKit
import SwiftUI

struct MediumWidget: Widget {
  let kind: String = "\(MediumWidget.self)"
  
  var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: self.kind,
      intent: ConfigurationIntent.self,
      provider: MediumProvider()
    ) { entry in
      MediumEntryView()
    }
    .configurationDisplayName("깔-끔하게 보기👻")
    .description("등록해놓은 위시리스트를 깔끔하게 볼래요?")
    .supportedFamilies([.systemMedium])
  }
}
