import WidgetKit

struct MediumHorizontalEntry: TimelineEntry {
    let date: Date
    let wishes: [Wish]
    
    static var preview: MediumHorizontalEntry {
        let wish = Wish()
        
        wish.title = "제목이 들어갑니다."
        wish.emoji = "🙈"
        wish.date = Date()
        
        return MediumHorizontalEntry(date: Date(), wishes: [wish, wish, wish])
    }
}
