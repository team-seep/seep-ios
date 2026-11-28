import Foundation

/// 골라서 보내기 카드 한 장에 그릴 것 (GH-125 R-3, R-5). 메모·사진·태그·저금·단계는 들고 있지 않는다(R-3 사적인 내용 보호)
struct ShareWishListCard: Equatable {
    struct Row: Equatable, Identifiable {
        let id: String
        let emoji: String
        let title: String
        /// 링크의 도메인(`www.` 제외). 링크가 없거나 링크 토글을 껐으면 nil (R-6)
        let domain: String?
        /// D-day 뱃지. D-day 토글을 껐으면 nil (R-6)
        let dday: DdayBadgeStyle?
    }

    /// 카드 제목 줄의 카테고리 이름 (R-3)
    let categoryTitle: String
    /// 고른 싶 전체 수. 제목 줄의 seep-blue 숫자 (R-3)
    let count: Int
    /// 오늘 날짜, 디자인 숫자 표기 "2026.11.04" (R-3)
    let dateText: String
    /// 카드에 그리는 싶 줄. 최대 `maxRowCount`, 넘으면 `maxRowCount - 1`줄 (R-5)
    let rows: [Row]
    /// 마지막 "외 n개" 줄의 n. 넘치지 않으면 0 (R-5)
    let moreCount: Int
}

/// 고른 싶으로 카드와 공유 글을 만든다. 순수 함수라 테스트가 바로 단언한다 (GH-125 R-3 ~ R-7)
enum ShareWishListContent {
    /// 카드 최대 줄 수. "외 n개" 줄을 포함한다 (R-5)
    static let maxRowCount = 10

    static func categoryTitle(_ category: Category) -> String {
        switch category {
        case .wantToDo: return Strings.ShareWishList.Category.wantToDo
        case .wantToGet: return Strings.ShareWishList.Category.wantToGet
        case .wantToGo: return Strings.ShareWishList.Category.wantToGo
        }
    }

    static func card(
        category: Category,
        wishes: [Wish],
        includesDday: Bool,
        includesLink: Bool,
        now: Date,
        calendar: Calendar
    ) -> ShareWishListCard {
        let overflows = wishes.count > maxRowCount
        let shown = overflows ? Array(wishes.prefix(maxRowCount - 1)) : wishes
        let rows = shown.map { wish in
            ShareWishListCard.Row(
                id: wish.id,
                emoji: wish.emoji,
                title: wish.title,
                domain: includesLink ? domain(of: wish.link) : nil,
                dday: includesDday ? DdayBadgeStyle(endDate: wish.endDate, today: now, calendar: calendar) : nil
            )
        }
        return ShareWishListCard(
            categoryTitle: categoryTitle(category),
            count: wishes.count,
            dateText: DisplayDate.fixed(now, pattern: "yyyy.MM.dd", timeZone: calendar.timeZone),
            rows: rows,
            moreCount: overflows ? wishes.count - shown.count : 0
        )
    }

    /// 공유 글. 첫 줄 "{카테고리} n개", 싶마다 "{이모지} {제목} (D-n)" + 다음 줄 전체 링크. 글에는 전부 넣는다 (R-5, R-7)
    static func text(
        category: Category,
        wishes: [Wish],
        includesDday: Bool,
        includesLink: Bool,
        now: Date,
        calendar: Calendar
    ) -> String {
        var lines = [Strings.ShareWishList.textTitleFormat(categoryTitle(category), wishes.count)]
        for wish in wishes {
            var line = [wish.emoji, wish.title].filter { !$0.isEmpty }.joined(separator: " ")
            // 일정없음은 글에 넣지 않는다 — 날짜를 정한 싶만 (R-7)
            if includesDday, wish.endDate != nil {
                let style = DdayBadgeStyle(endDate: wish.endDate, today: now, calendar: calendar)
                line += " (\(ddayText(style)))"
            }
            lines.append(line)
            if includesLink, hasLink(wish.link) {
                lines.append(wish.link.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return lines.joined(separator: "\n")
    }

    /// 홈 뱃지와 같은 문구 (R-3)
    static func ddayText(_ style: DdayBadgeStyle) -> String {
        style.text(farFuture: Strings.homeInFarFurture, noDate: Strings.homeNoDeanline)
    }

    /// 링크 토글을 보일지 — 링크 있는 싶이 하나라도 있어야 한다 (R-6)
    static func hasAnyLink(_ wishes: [Wish]) -> Bool {
        wishes.contains { hasLink($0.link) }
    }

    /// "https://www.apple.com/kr/…" → "apple.com". 주소로 읽을 수 없으면 nil
    static func domain(of link: String) -> String? {
        guard hasLink(link),
              let host = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines))?.host(),
              !host.isEmpty else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private static func hasLink(_ link: String) -> Bool {
        !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
