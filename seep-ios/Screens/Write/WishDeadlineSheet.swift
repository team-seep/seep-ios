import SwiftUI

/// "언제까지 이루고 싶어요?" 시트 항목 (GH-118 R-3). rawValue 는 `select_deadline_kind` 로그의 `type` 값
enum WishDeadlineOption: String, CaseIterable, Equatable {
    /// 달력에서 날짜 고르기
    case date
    case month
    case year
    case nextYear = "next_year"
    /// 언젠가(기한 없음)
    case someday = "none"

    /// 고르면 저장할 기한 종류. 날짜·언젠가는 날짜 기한
    var deadlineKind: DeadlineKind {
        switch self {
        case .date, .someday: return .date
        case .month: return .month
        case .year: return .year
        case .nextYear: return .nextYear
        }
    }

    init(kind: DeadlineKind) {
        switch kind {
        case .date: self = .date
        case .month: self = .month
        case .year: self = .year
        case .nextYear: self = .nextYear
        }
    }
}

/// 시트 한 줄: 이름 · 오른쪽 실제 마감("12월 31일까지") · 고른 항목 표시
struct WishDeadlineOptionRow: Equatable, Identifiable {
    let option: WishDeadlineOption
    let title: String
    let detail: String
    let isSelected: Bool

    var id: String { option.rawValue }

    /// 오른쪽 마감은 지금 고르면 저장될 날짜다 (R-3). 해가 다르면 연도를 붙인다
    static func rows(
        isDeadlineEnabled: Bool,
        kind: DeadlineKind,
        now: Date,
        calendar: Calendar = .current,
        locale: Locale = AppLanguage.shared.locale
    ) -> [WishDeadlineOptionRow] {
        let selected: WishDeadlineOption = isDeadlineEnabled ? WishDeadlineOption(kind: kind) : .someday
        return WishDeadlineOption.allCases.map { option in
            let detail: String
            switch option {
            case .date:
                detail = Strings.Deadline.Sheet.pickDateDetail
            case .month, .year, .nextYear:
                let end = option.deadlineKind.periodEnd(from: now, calendar: calendar) ?? now
                detail = SoftDeadline.untilText(end, now: now, calendar: calendar, locale: locale)
            case .someday:
                detail = Strings.Deadline.Sheet.somedayDetail
            }
            return WishDeadlineOptionRow(option: option, title: title(option), detail: detail, isSelected: option == selected)
        }
    }

    private static func title(_ option: WishDeadlineOption) -> String {
        switch option {
        case .date: return Strings.Deadline.Sheet.pickDate
        case .month: return Strings.Deadline.Period.thisMonth
        case .year: return Strings.Deadline.Period.thisYear
        case .nextYear: return Strings.Deadline.Period.nextYear
        case .someday: return Strings.Deadline.Sheet.someday
        }
    }
}

/// 언제까지 시트 (GH-118 R-3). 제목 · 설명 · 항목 5줄(구분선) · 닫기
struct WishDeadlineSheet: View {
    let rows: [WishDeadlineOptionRow]
    let onSelect: (WishDeadlineOption) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Deadline.Sheet.title)
                .font(.appleBold(size: 22))
                .foregroundStyle(Color.gray5)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(Strings.Deadline.Sheet.description)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.gray2_5)
                            .frame(height: 1)
                    }
                    rowButton(row)
                }
            }
            .padding(.top, 16)
            Button(action: onClose) {
                Text(Strings.WishForm.close)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func rowButton(_ row: WishDeadlineOptionRow) -> some View {
        Button {
            onSelect(row.option)
        } label: {
            HStack(spacing: 8) {
                Text(verbatim: row.title)
                    .font(row.isSelected ? .appleBold(size: 16) : .appleRegular(size: 16))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(verbatim: row.option == .date ? row.detail + " ›" : row.detail)
                    .font(.appleRegular(size: 14))
                    .foregroundStyle(row.isSelected ? Color.seepBlue : Color.gray4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if row.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.seepBlue)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(row.isSelected ? .isSelected : [])
    }
}
