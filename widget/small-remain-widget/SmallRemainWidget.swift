import WidgetKit
import SwiftUI
import Intents

struct SmallRemainWidget: Widget {
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "\(SmallRemainWidget.self)",
            provider: SmallRemainProvider()
        ) { entry in
            SmallRemainEntryView(entry: entry)
        }
        .configurationDisplayName("남은 위시는 몇개!?")
        .description("나의 꿈을 향해 한걸음 쉽게 다가가요!")
        .supportedFamilies([.systemSmall])
    }
}
