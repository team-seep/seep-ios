import Foundation

/// 이룬 싶 목록의 한 달 묶음 (R-20)
struct FinishedSection: Equatable, Identifiable {
    /// "2026-10"
    let id: String
    /// "2026년 10월"
    let title: String
    let rows: [WishRowModel]
}

/// 완료한 위시를 최근 이룬 순으로 월별로 묶고, 줄 보조 문구를 만든다 (GH-64 R-20, TC-7, TC-8)
enum FinishedSectionBuilder {
    /// - Parameter filter: nil 이면 전체 카테고리
    static func sections(
        finishedWishes: [Wish],
        filter: Category?,
        calendar: Calendar = .current
    ) -> [FinishedSection] {
        let wishes = finishedWishes
            .filter { $0.isSuccess && (filter == nil || $0.category == filter) }
            .sorted { finishDate(of: $0) > finishDate(of: $1) }

        var sections: [FinishedSection] = []
        for wish in wishes {
            let components = calendar.dateComponents([.year, .month], from: finishDate(of: wish))
            let year = components.year ?? 0
            let month = components.month ?? 0
            let id = String(format: "%04d-%02d", year, month)
            let row = rowModel(wish: wish, filter: filter, calendar: calendar)

            if let last = sections.last, last.id == id {
                sections[sections.count - 1] = FinishedSection(id: id, title: last.title, rows: last.rows + [row])
            } else {
                sections.append(FinishedSection(
                    id: id,
                    title: DisplayDate.yearMonth(year: year, month: month, calendar: calendar),
                    rows: [row]
                ))
            }
        }
        return sections
    }

    /// "{일}일 이룸" + 소감이 있으면 " · “소감”", 소감이 없고 전체 필터면 " · {카테고리}" (R-20)
    static func subtitle(wish: Wish, filter: Category?, calendar: Calendar = .current) -> String {
        let day = calendar.component(.day, from: finishDate(of: wish))
        let dayText = Strings.Finished.Row.dayFormat(day)
        let note = wish.finishNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty {
            return dayText + " · " + Strings.Finished.Row.noteFormat(note)
        }
        if filter == nil {
            return dayText + " · " + wish.category.title
        }
        return dayText
    }

    private static func rowModel(wish: Wish, filter: Category?, calendar: Calendar) -> WishRowModel {
        WishRowModel(
            id: wish.id,
            emoji: wish.emoji,
            title: wish.title,
            dday: DdayBadgeStyle(endDate: wish.endDate, calendar: calendar),
            tag: nil,
            isFinished: true,
            subtitle: subtitle(wish: wish, filter: filter, calendar: calendar)
        )
    }

    /// 완료일이 없는 옛 데이터는 만든 날로 둔다
    private static func finishDate(of wish: Wish) -> Date {
        wish.finishDate ?? wish.createdAt
    }
}
