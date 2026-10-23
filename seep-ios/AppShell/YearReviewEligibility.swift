import Foundation

/// 연말 회고를 보여줄 연도와 그해 이룬 싶 수 (GH-34 R-8, R-9).
/// 싶 탭 배너·이룬 싶 탭 카드(GH-64 R-18)가 같이 쓴다. 닫은 연도 처리는 배너만 한다
struct YearReviewEligibility: Equatable {
    let year: Int
    let count: Int

    /// Remote Config 기간 안이고 그해 이룬 싶이 1개 이상이면 값을 돌려준다
    static func make(
        remoteConfigRepository: RemoteConfigRepository,
        wishRepository: WishRepository,
        now: Date,
        calendar: Calendar,
        closedYears: [Int] = []
    ) -> YearReviewEligibility? {
        guard let period = remoteConfigRepository.fetchYearReviewPeriod(),
              let year = period.targetYear(now: now, calendar: calendar),
              !closedYears.contains(year),
              let range = YearReviewSummary.dateRange(year: year, calendar: calendar) else { return nil }

        let count = wishRepository.fetchFinishedWishes(from: range.from, to: range.to).count
        guard count > 0 else { return nil }
        return YearReviewEligibility(year: year, count: count)
    }
}
