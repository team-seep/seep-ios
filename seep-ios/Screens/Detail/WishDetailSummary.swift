import Foundation

/// 위시 상세 문서 머리(제목 블록·D-day 줄·메타 줄·메모)에 보일 문구 (GH-59 R-2~R-5, R-12).
/// UIKit 없이 위시 → 문구로만 바꿔 유닛 테스트한다.
struct WishDetailSummary: Equatable {
    struct DdayLine: Equatable {
        /// "D-61" · "D-Day" · "D+5" · "일정없음" · "먼훗날"
        let text: String
        let tone: DdayTone
        /// 단어(일정없음·먼훗날)면 작게 쓴다
        let isWord: Bool
        /// "12월 20일 (일)까지" · "오늘까지" · "10월 15일 (목)이었어요". 날짜 없음이면 nil
        let dateText: String?
    }

    enum MetaItem: Equatable {
        case category(String)
        case notification(String)
        case hashtag(String)
    }

    let emoji: String
    let title: String
    let ddayLine: DdayLine
    /// 카테고리 · 알림 요약 · #해시태그. 없는 항목은 빠진다 (R-4)
    let metaItems: [MetaItem]
    /// 비어 있으면 nil — 메모 칸을 숨긴다 (R-5)
    let memo: String?

    init(wish: Wish, now: Date = Date(), calendar: Calendar = .current) {
        self.emoji = wish.emoji
        self.title = wish.title
        self.ddayLine = Self.ddayLine(endDate: wish.endDate, now: now, calendar: calendar)
        self.metaItems = Self.metaItems(wish: wish, calendar: calendar)
        let memo = wish.memo.trimmingCharacters(in: .whitespacesAndNewlines)
        self.memo = memo.isEmpty ? nil : wish.memo
    }

    /// D-day 줄. 작성·수정 문서 머리도 같은 줄을 쓴다 (GH-70 R-2)
    static func ddayLine(endDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> DdayLine {
        let style = DdayStyle(endDate: endDate, now: now, calendar: calendar)
        return DdayLine(
            text: style.text,
            tone: style.tone,
            isWord: style.isWord,
            dateText: dateText(style: style, endDate: endDate, calendar: calendar)
        )
    }

    /// 스크롤해 제목이 지나가면 상단 바 제목 옆에 붙일 작은 D-day. 일정없음·먼훗날은 붙이지 않는다 (R-8)
    var navigationDday: DdayLine? {
        return ddayLine.isWord ? nil : ddayLine
    }

    /// 메타 줄을 한 문자열로 (접근성 라벨)
    var metaText: String {
        return metaItems.map { item in
            switch item {
            case .category(let text), .notification(let text), .hashtag(let text):
                return text
            }
        }
        .joined(separator: " · ")
    }

    private static func dateText(style: DdayStyle, endDate: Date?, calendar: Calendar) -> String? {
        guard let endDate else { return nil }

        switch style.kind {
        case .noDeadline:
            return nil
        case .today:
            return Strings.Detail.Dday.untilToday
        case .past:
            return Strings.Detail.Dday.pastFormat(format(endDate, pattern: "M월 d일 (E)", calendar: calendar))
        case .remaining:
            return Strings.Detail.Dday.untilFormat(format(endDate, pattern: "M월 d일 (E)", calendar: calendar))
        case .farFuture:
            return Strings.Detail.Dday.untilFormat(format(endDate, pattern: "yyyy년 M월 d일 (E)", calendar: calendar))
        }
    }

    private static func metaItems(wish: Wish, calendar: Calendar) -> [MetaItem] {
        var items: [MetaItem] = [.category(categoryText(wish.category))]

        if let first = wish.notifications.first {
            let firstText = "\(notificationTypeText(first.type)) \(format(first.time, pattern: "a h:mm", calendar: calendar))"
            let extraCount = wish.notifications.count - 1
            items.append(.notification(
                extraCount > 0 ? Strings.Detail.Meta.notificationMoreFormat(firstText, extraCount) : firstText
            ))
        }

        let hashtag = wish.hashtag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !hashtag.isEmpty {
            let name = HashtagType(rawValue: hashtag)?.description ?? hashtag
            items.append(.hashtag("#\(name)"))
        }
        return items
    }

    private static func categoryText(_ category: Category) -> String {
        switch category {
        case .wantToDo:
            return Strings.commonCategoryWantToDo
        case .wantToGet:
            return Strings.commonCategoryWantToGet
        case .wantToGo:
            return Strings.commonCategoryWantToGo
        }
    }

    private static func notificationTypeText(_ type: SeepNotification.NotificationType) -> String {
        switch type {
        case .targetDay:
            return Strings.notificationTypeTargatDay
        case .dayAgo:
            return Strings.notificationTypeBeforeDay
        case .twoDayAgo:
            return Strings.notificationTypeBeforeTwoDay
        case .weekAgo:
            return Strings.notificationTypeBeforeWeek
        case .everyDay:
            return Strings.notificationTypeEveryday
        }
    }

    private static func format(_ date: Date, pattern: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
