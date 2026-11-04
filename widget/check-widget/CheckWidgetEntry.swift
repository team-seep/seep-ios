import WidgetKit

struct CheckWidgetEntry: TimelineEntry {
    let date: Date
    /// 미완료 위시 + 오늘 위젯에서 완료한 위시, D-day 순 최대 3개 (R-1, R-4)
    let wishes: [Wish]

    static let maxCount = 3

    static var preview: CheckWidgetEntry {
        let steps = [
            WishStep(title: Strings.Widget.Preview.step1, isDone: true, order: 0),
            WishStep(title: Strings.Widget.Preview.step2, order: 1),
            WishStep(title: Strings.Widget.Preview.step3, order: 2)
        ]
        return CheckWidgetEntry(date: Date(), wishes: [
            Wish(emoji: "🌴", title: Strings.Widget.Preview.travelWish, endDate: Date(), steps: steps),
            Wish(emoji: "🎸", title: Strings.Widget.Preview.guitarWish)
        ])
    }
}
