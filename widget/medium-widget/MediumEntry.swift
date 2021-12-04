import WidgetKit

struct MediumEntry: TimelineEntry {
    let date: Date
    let wishes: [Wish]
    
    static var preview: MediumEntry {
        let wish = Wish()
        
        wish.title = "제목이 들어갑니다."
        wish.emoji = "🙈"
        wish.date = Date()
        
        return MediumEntry(date: Date(), wishes: [wish, wish, wish])
    }
}
