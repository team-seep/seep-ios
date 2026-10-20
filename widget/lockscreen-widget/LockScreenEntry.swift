import WidgetKit

/// 잠금화면 위젯 2종("다가오는 싶 D-day", "남은 싶")이 같이 쓰는 엔트리 (GH-47)
struct LockScreenEntry: TimelineEntry {
    let date: Date
    /// 가장 가까운 D-day 위시. nil 이면 빈 상태
    let wish: Wish?
    /// 완료하지 않은 위시 수 (전체 카테고리)
    let remainCount: Int

    var ddayText: DdayText? {
        guard let endDate = wish?.endDate else { return nil }
        return DdayText.make(endDate: endDate, now: date)
    }

    var ddayURL: URL? {
        if let wish {
            return WidgetDeepLink.wish(id: wish.id, source: .lockscreenDday).url
        }
        return WidgetDeepLink.home(source: .lockscreenDday).url
    }

    var remainURL: URL? {
        return WidgetDeepLink.home(source: .lockscreenRemain).url
    }

    static var preview: LockScreenEntry {
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let wish = Wish(emoji: "🌴", title: "제주도 한 달 살기", endDate: endDate)

        return LockScreenEntry(date: Date(), wish: wish, remainCount: 7)
    }
}
