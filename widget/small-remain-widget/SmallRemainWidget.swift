import WidgetKit
import SwiftUI
import Intents

struct SmallRemainWidget: Widget {
  let category: Category
  
  init() {
    self.category = .wantToDo
  }
  
  init(category: Category) {
    self.category = category
  }
  
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "\(SmallRemainWidget.self)-" + self.category.rawValue,
      provider: SmallRemainProvider()
    ) { entry in
      SmallRemainEntryView(categoryData: SmallRemainWidgetData(category: category, count: 0))
    }
    .configurationDisplayName("남은 위시는 몇개!?")
    .description("나의 꿈을 향해 한걸음 쉽게 다가가요!")
    .supportedFamilies([.systemSmall])
  }
}
