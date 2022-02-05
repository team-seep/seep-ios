import WidgetKit

struct MediumVerticalEntry: TimelineEntry {
    let date: Date
    let wishes: [Wish]
    
    static var preview: MediumVerticalEntry {
        let wish = Wish(
            emoji: "🙈",
            title: "제목이 들어갑니다.",
            endDate: Date()
        )
        
        return MediumVerticalEntry(date: Date(), wishes: [wish, wish, wish])
    }
}
