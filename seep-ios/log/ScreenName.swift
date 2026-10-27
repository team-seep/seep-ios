import Foundation

struct ScreenName: RawRepresentable, Hashable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ScreenName {
    static let empty = ScreenName(rawValue: "empty")

    static let splash = ScreenName(rawValue: "splash")
    /// 화면과 무관하게 앱 실행 때 보내는 이벤트 (GH-79 db_migration)
    static let appLaunch = ScreenName(rawValue: "app_launch")
    static let home = ScreenName(rawValue: "home")
    static let sortOrderBottomSheet = ScreenName(rawValue: "sort_order_bottom_sheet")
    static let finishNoteBottomSheet = ScreenName(rawValue: "finish_note_bottom_sheet")
    static let futureLetterBottomSheet = ScreenName(rawValue: "future_letter_bottom_sheet")
    static let write = ScreenName(rawValue: "write")
    static let wishDetail = ScreenName(rawValue: "wish_detail")
    static let wishEdit = ScreenName(rawValue: "wish_edit")
    static let finished = ScreenName(rawValue: "finished")
    static let notification = ScreenName(rawValue: "notification")
    static let sharePhoto = ScreenName(rawValue: "share_photo")
    static let wishSearch = ScreenName(rawValue: "wish_search")
    static let yearReview = ScreenName(rawValue: "year_review")
    static let yearReviewList = ScreenName(rawValue: "year_review_list")
    static let badgeBottomSheet = ScreenName(rawValue: "badge_bottom_sheet")
    static let badgeCollection = ScreenName(rawValue: "badge_collection")
    static let placeSearchBottomSheet = ScreenName(rawValue: "place_search_bottom_sheet")
    static let placeMap = ScreenName(rawValue: "place_map")
    static let writeControl = ScreenName(rawValue: "write_control")
    static let checkWidget = ScreenName(rawValue: "check_widget")
    static let lockScreenWidget = ScreenName(rawValue: "lock_screen_widget")
    static let appLockBottomSheet = ScreenName(rawValue: "app_lock_bottom_sheet")
    static let appLock = ScreenName(rawValue: "app_lock")
    static let writeCategorySheet = ScreenName(rawValue: "write_category_sheet")
    static let settings = ScreenName(rawValue: "settings")
    static let widgetGuide = ScreenName(rawValue: "widget_guide")
    static let controlGuide = ScreenName(rawValue: "control_guide")
    static let license = ScreenName(rawValue: "license")
    /// 상세 일지 한 줄 남기기 시트 (GH-95)
    static let journalBottomSheet = ScreenName(rawValue: "journal_bottom_sheet")
}
