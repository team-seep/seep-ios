import WidgetKit

struct SmallRemainEntry: TimelineEntry {
    let date: Date
    let category: Category
    let count: Int
    /// 그 카테고리에서 완료일이 가장 가까운 위시. 아래 작은 줄에 보인다 (GH-87 R-1)
    let nextWish: Wish?

    var copy: SmallRemainCopy { SmallRemainCopy(category: category, count: count) }
}
