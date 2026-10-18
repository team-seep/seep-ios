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
    static let home = ScreenName(rawValue: "home")
    static let sortOrderBottomSheet = ScreenName(rawValue: "sort_order_bottom_sheet")
    static let finishNoteBottomSheet = ScreenName(rawValue: "finish_note_bottom_sheet")
    static let write = ScreenName(rawValue: "write")
    static let wishDetail = ScreenName(rawValue: "wish_detail")
    static let wishEdit = ScreenName(rawValue: "wish_edit")
    static let finished = ScreenName(rawValue: "finished")
    static let notification = ScreenName(rawValue: "notification")
    static let sharePhoto = ScreenName(rawValue: "share_photo")
    static let yearReview = ScreenName(rawValue: "year_review")
    static let yearReviewList = ScreenName(rawValue: "year_review_list")
}
