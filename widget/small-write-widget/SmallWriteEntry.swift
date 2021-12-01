import WidgetKit

struct SmallWriteEntry: TimelineEntry {
  let date: Date
  let category: Category
  
  init(date: Date) {
    self.date = date
    self.category = [
      Category.wantToGo,
      Category.wantToGet,
      Category.wantToDo,
    ].randomElement() ?? .wantToDo
  }
}
