import Foundation

extension WishRowModel {
    /// 도메인 위시 → 공용 위시 줄 값. 해시태그는 기본 태그면 설명 문구로 바꾼다
    init(wish: Wish, subtitle: String? = nil, today: Date = Date()) {
        let tag = wish.hashtag.isEmpty ? nil : (HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag)
        self.init(
            id: wish.id,
            emoji: wish.emoji,
            title: wish.title,
            dday: DdayBadgeStyle(endDate: wish.endDate, today: today),
            tag: tag,
            isFinished: wish.isSuccess,
            subtitle: subtitle
        )
    }
}
