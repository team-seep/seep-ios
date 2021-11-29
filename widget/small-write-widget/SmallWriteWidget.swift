import WidgetKit
import SwiftUI
import Intents

struct SmallWriteWidget: Widget {
  let category: Category
  let description: String
  
  init() {
    self.category = .wantToDo
    self.description = "하고싶은 것"
  }
  
  init(category: Category) {
    self.category = category
    
    switch category {
    case .wantToDo:
      self.description = "하고싶은 것"
    case .wantToGet:
      self.description = "갖고싶은 것"
    case .wantToGo:
      self.description = "가고싶은 곳"
    }
  }
  
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "\(SmallWriteWidget.self)-" + self.category.rawValue,
      provider: SmallWriteProvider()
    ) { entry in
      SmallWriteEntryView(categoryData: SmallWriteWidgetData(category: category))
    }
    .configurationDisplayName("빠르게 등록하기")
    .description("누구보다 빠르게 " + self.description + "을 등록해보는건 어때요?")
    .supportedFamilies([.systemSmall])
  }
}
