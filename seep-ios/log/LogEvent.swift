import Foundation

/// GA(Firebase Analytics)로 보내는 이벤트. 형식은 가슴속 3천원 iOS Log 모듈과 같다.
/// 모든 이벤트에는 `screen` 파라미터가 붙고, 클릭·노출은 `object_type` / `object_id` 로 대상을 구분한다.
protocol LogEventType {
    var screen: ScreenName { get set }
    var name: EventName { get set }
    var extraParameters: [ParameterName: Any]? { get set }
}

extension LogEventType {
    var parameters: [String: Any] {
        var result: [String: Any] = [:]

        if let extraParameters {
            extraParameters.forEach { key, value in
                if let objectId = value as? LogObjectId {
                    result[key.rawValue] = objectId.rawValue
                } else if let objectType = value as? LogObjectType {
                    result[key.rawValue] = objectType.rawValue
                } else {
                    result[key.rawValue] = value
                }
            }
        }

        result[ParameterName.screen.rawValue] = screen.rawValue
        return result
    }
}

struct ClickEvent: LogEventType {
    var screen: ScreenName
    var name: EventName = .click
    var extraParameters: [ParameterName: Any]?

    init(
        screen: ScreenName,
        objectType: LogObjectType,
        objectId: LogObjectId,
        extraParameters: [ParameterName: Any]? = nil
    ) {
        self.screen = screen

        var clickObject: [ParameterName: Any] = [
            .objectId: objectId,
            .objectType: objectType
        ]

        if let extraParameters {
            clickObject.merge(extraParameters) { _, new in new }
        }

        self.extraParameters = clickObject
    }
}

struct ImpressionEvent: LogEventType {
    var screen: ScreenName
    var name: EventName = .impression
    var extraParameters: [ParameterName: Any]?

    init(
        screen: ScreenName,
        objectType: LogObjectType,
        objectId: LogObjectId,
        extraParameters: [ParameterName: Any]? = nil
    ) {
        self.screen = screen

        var impressionObject: [ParameterName: Any] = [
            .objectId: objectId,
            .objectType: objectType
        ]

        if let extraParameters {
            impressionObject.merge(extraParameters) { _, new in new }
        }

        self.extraParameters = impressionObject
    }
}

struct CustomEvent: LogEventType {
    var screen: ScreenName
    var name: EventName
    var extraParameters: [ParameterName: Any]?

    init(
        screen: ScreenName,
        name: EventName,
        extraParameters: [ParameterName: Any]? = nil
    ) {
        self.screen = screen
        self.name = name
        self.extraParameters = extraParameters
    }
}

enum LogObjectType: String {
    case button
    case card
    case tab
    case banner
    case widget
    case notification
}

/// 클릭·노출 대상. 새 기능의 트래킹 이벤트는 여기에 케이스를 추가한다 (docs/process/planning.md "트래킹 이벤트").
enum LogObjectId: String {
    case write
    case wish
    case finish
    case delete
    case edit
    case share
    case sortOrder = "sort_order"
    case onlyFinished = "only_finished"
    case viewType = "view_type"
    case category
    case addStep = "add_step"
    case checkStep = "check_step"
    case addSaving = "add_saving"
    case saveSaving = "save_saving"
    case finishNoteSheet = "finish_note_sheet"
    case saveFinishNote = "save_finish_note"
    case skipFinishNote = "skip_finish_note"
    case addCalendar = "add_calendar"
    case confirmAddCalendar = "confirm_add_calendar"
    case search
    case searchResult = "search_result"
    case searchEmpty = "search_empty"
    case yearReviewBanner = "year_review_banner"
    case closeYearReviewBanner = "close_year_review_banner"
    case shareYearReview = "share_year_review"
    case badgeCollection = "badge_collection"
    case newBadge = "new_badge"
    case viewBadges = "view_badges"
    case pinWish = "pin_wish"
    case unpinWish = "unpin_wish"
    case pinLimitToast = "pin_limit_toast"
    case wishLink = "wish_link"
    case wishLinkPreview = "wish_link_preview"
    case pasteWishLink = "paste_wish_link"
    case sleepingWishCard = "sleeping_wish_card"
    case keepSleepingWish = "keep_sleeping_wish"
    case releaseSleepingWish = "release_sleeping_wish"
    case addPlace = "add_place"
    case selectPlace = "select_place"
    case placeMap = "place_map"
    case placeMapWish = "place_map_wish"
    case addPhoto = "add_photo"
    case changePhoto = "change_photo"
    case deletePhoto = "delete_photo"
    case appLock = "app_lock"
    case enableAppLock = "enable_app_lock"
    case disableAppLock = "disable_app_lock"
    case unlockApp = "unlock_app"
}
