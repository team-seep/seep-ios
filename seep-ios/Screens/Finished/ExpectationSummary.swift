import Foundation

/// 이룬 싶 탭 "이뤄 보니 n개가 기대보다 좋았어요" 요약 (GH-139 R-6).
/// 기대 비교를 남긴 싶만 센다. 카테고리 줄은 기록이 없어도 세 줄 다 둔다(TC-7)
struct ExpectationSummary: Equatable {
    struct Row: Equatable, Identifiable {
        let category: Category
        let betterCount: Int
        /// 이 카테고리에서 기대 비교를 남긴 싶 수. 0 이면 "기록 없음"
        let recordedCount: Int

        var id: String { category.rawValue }

        /// 막대 채움 비율 0...1. 기록이 없으면 0
        var ratio: Double {
            recordedCount == 0 ? 0 : Double(betterCount) / Double(recordedCount)
        }
    }

    /// 기록한 싶이 이보다 적으면 카드를 숨긴다 (R-6, TC-8)
    static let minimumRecordedCount = 3

    let betterCount: Int
    let recordedCount: Int
    /// 하고 / 갖고 / 가고 순서
    let rows: [Row]

    /// - Returns: 기록한 싶이 `minimumRecordedCount`개보다 적으면 nil
    static func make(finishedWishes: [Wish]) -> ExpectationSummary? {
        let recorded = finishedWishes.filter { $0.isSuccess && $0.finishFeeling != nil }
        guard recorded.count >= minimumRecordedCount else { return nil }
        let categories: [Category] = [.wantToDo, .wantToGet, .wantToGo]
        let rows = categories.map { category in
            let wishes = recorded.filter { $0.category == category }
            return Row(
                category: category,
                betterCount: wishes.filter { $0.finishFeeling == .better }.count,
                recordedCount: wishes.count
            )
        }
        return ExpectationSummary(
            betterCount: rows.reduce(0) { $0 + $1.betterCount },
            recordedCount: recorded.count,
            rows: rows
        )
    }
}
