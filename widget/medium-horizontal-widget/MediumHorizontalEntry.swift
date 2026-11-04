import WidgetKit

struct MediumHorizontalEntry: TimelineEntry {
    let date: Date
    let wishes: [Wish]
    
    static var preview: MediumHorizontalEntry {
        let wish = Wish(
            emoji: "🙈",
            title: Strings.Widget.Preview.wishTitle,
            endDate: Date()
        )
        
        return MediumHorizontalEntry(date: Date(), wishes: [wish, wish, wish])
    }
}
