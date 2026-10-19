import WidgetKit

struct CheckWidgetEntry: TimelineEntry {
    let date: Date
    /// 미완료 위시 + 오늘 위젯에서 완료한 위시, D-day 순 최대 3개 (R-1, R-4)
    let wishes: [Wish]

    static let maxCount = 3

    static var preview: CheckWidgetEntry {
        let steps = [
            WishStep(title: "항공권 사기", isDone: true, order: 0),
            WishStep(title: "숙소 예약하기", order: 1),
            WishStep(title: "렌터카 예약하기", order: 2)
        ]
        return CheckWidgetEntry(date: Date(), wishes: [
            Wish(emoji: "🌴", title: "제주도 한 달 살기", endDate: Date(), steps: steps),
            Wish(emoji: "🎸", title: "기타로 노래 한 곡 치기")
        ])
    }
}
