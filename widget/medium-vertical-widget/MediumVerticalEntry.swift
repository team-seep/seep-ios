import WidgetKit

struct MediumVerticalEntry: TimelineEntry {
    let date: Date
    let wishes: [Wish]
    
    static var preview: MediumVerticalEntry {
        let wish = Wish(
            emoji: "🙈",
            title: Strings.Widget.Preview.wishTitle,
            endDate: Date()
        )
        
        return MediumVerticalEntry(date: Date(), wishes: [wish, wish, wish])
    }
}
