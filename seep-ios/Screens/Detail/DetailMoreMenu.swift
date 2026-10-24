import Foundation

/// 상세 ⋯ 메뉴(액션 시트) 구성 (GH-59 R-9). "수정하기"는 없다 — 수정은 상단 바 "수정" 버튼으로만 (사용자 결정).
/// 홈에서 연 상세: 캘린더에 추가(날짜 있을 때) · 공유하기 · 삭제하기 · 취소하기 — 사진·편지 지우기는 수정 문서에서 (GH-61 R-9)
/// 완료 목록에서 연 상세: 완료 취소하기 · 사진 지우기(사진 있을 때) · 공유하기 · 취소하기 (GH-61 R-12)
enum DetailMoreMenu {
    enum Item: Equatable {
        /// 이미 추가했으면 "캘린더에 추가됨" — 누르면 기존(GH-28) 확인 알림 흐름
        case addCalendar(isAdded: Bool)
        case share
        case deletePhoto
        case delete
        case cancelFinish

        var title: String {
            switch self {
            case .addCalendar(let isAdded):
                return isAdded ? Strings.Detail.Calendar.added : Strings.Detail.Calendar.add
            case .share:
                return Strings.detailActionSheetShare
            case .deletePhoto:
                return Strings.Detail.Photo.delete
            case .delete:
                return Strings.detailActionSheetDelete
            case .cancelFinish:
                return Strings.detailActionSheetCancelFinish
            }
        }

        var isDestructive: Bool {
            return self == .delete
        }
    }

    struct Context: Equatable {
        let mode: DetailMode
        /// `WishCalendarViewModel.output.isVisible` — 홈에서 연 미완료 위시 + 날짜 있음
        let isCalendarVisible: Bool
        let isCalendarAdded: Bool
        let hasPhoto: Bool
    }

    /// 취소하기는 액션 시트의 cancel 항목이라 목록에 넣지 않는다
    static func items(context: Context) -> [Item] {
        var items: [Item] = []
        switch context.mode {
        case .fromHome:
            if context.isCalendarVisible {
                items.append(.addCalendar(isAdded: context.isCalendarAdded))
            }
            items.append(.share)
            items.append(.delete)
        case .fromFinish:
            items.append(.cancelFinish)
            if context.hasPhoto {
                items.append(.deletePhoto)
            }
            items.append(.share)
        }
        return items
    }
}
