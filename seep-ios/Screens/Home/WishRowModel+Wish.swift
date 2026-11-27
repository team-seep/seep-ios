import Foundation

extension WishRowModel {
    /// 도메인 위시 → 공용 위시 줄 값. 해시태그는 기본 태그면 설명 문구로 바꾼다
    init(wish: Wish, subtitle: String? = nil, today: Date = Date()) {
        let tag = wish.hashtag.isEmpty ? nil : HashtagType.displayName(for: wish.hashtag)
        self.init(
            id: wish.id,
            emoji: wish.emoji,
            title: wish.title,
            dday: DdayBadgeStyle(wish: wish, today: today),
            tag: tag,
            extraTagCount: max(wish.tags.count - 1, 0),
            isFinished: wish.isSuccess,
            subtitle: subtitle
        )
    }
}

extension DdayBadgeStyle {
    /// 위시의 D-day 뱃지. 기간 기한이면 "이번 달 안" · "올해 안" · "내년까지" · "올해가 지났어요"를 쓴다 (GH-118 R-4, R-6)
    init(wish: Wish, today: Date = Date(), calendar: Calendar = .current) {
        self.init(
            endDate: wish.endDate,
            label: SoftDeadline(wish: wish, now: today, calendar: calendar)?.badgeText,
            today: today,
            calendar: calendar
        )
    }
}
