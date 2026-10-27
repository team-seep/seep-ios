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
    case controlWrite = "control_write"
    case shortcutWrite = "shortcut_write"
    case widgetCheckStep = "widget_check_step"
    case widgetFinishWish = "widget_finish_wish"
    case widgetUnfinishWish = "widget_unfinish_wish"
    case lockscreenDdayWidget = "lockscreen_dday_widget"
    case lockscreenRemainWidget = "lockscreen_remain_widget"
    case appLock = "app_lock"
    case enableAppLock = "enable_app_lock"
    case disableAppLock = "disable_app_lock"
    case unlockApp = "unlock_app"
    // GH-64 메인 탭 · 적기 시트
    case tabWish = "tab_wish"
    case tabFinished = "tab_finished"
    case tabWrite = "tab_write"
    case tabSettings = "tab_settings"
    case writeCategory = "write_category"
    case finishedTabDot = "finished_tab_dot"
    // GH-64 이룬 싶·설정
    case yearReviewCard = "year_review_card"
    case notificationSetting = "notification_setting"
    case viewTypeSetting = "view_type_setting"
    /// 설정 "화면 모드"에서 고름 (+type) (GH-85)
    case selectAppearance = "select_appearance"
    /// 설정 "시작 카테고리"에서 고름 (+type) (GH-86)
    case selectStartCategory = "select_start_category"
    /// 홈 "선택" → 선택 모드 (GH-86)
    case selectWishes = "select_wishes"
    /// 선택 모드 일괄 삭제 확인 (+count) (GH-86)
    case deleteSelectedWishes = "delete_selected_wishes"
    case widgetGuide = "widget_guide"
    case controlGuide = "control_guide"
    case rateApp = "rate_app"
    case contact = "contact"
    case license = "license"
    case detailEdit = "detail_edit"
    case detailMore = "detail_more"
    /// 작성·수정 문서 더하기 칩 (GH-70)
    case addBlock = "add_block"
    case discardWrite = "discard_write"
    /// 상세 "미래의 나에게" ＋ 쓰기·다시 쓰기 (GH-61)
    case writeFutureLetter = "write_future_letter"
    /// 편지 시트 봉인하기 (GH-61)
    case sealFutureLetter = "seal_future_letter"
    /// 완료 순간 열린 편지 카드 노출 (GH-61)
    case futureLetter = "future_letter"
    /// 이어서 적기 (소감 시트·이룬 싶 상세 ⋯) (GH-84)
    case chainNextWish = "chain_next_wish"
    /// 이어서 연 작성 화면에서 저장 (GH-84)
    case saveChainedWish = "save_chained_wish"
    /// 상세 "이어지는 싶" 섹션에서 다른 싶 줄 (GH-84)
    case chainWishRow = "chain_wish_row"
    /// 필터 바 "순서 바꾸기" (GH-73)
    case reorderWishes = "reorder_wishes"
    /// 순서 바꾸기 모드에서 위시를 옮겨 놓음 (GH-73)
    case moveWish = "move_wish"
    /// 홈 "예전 위시를 불러오지 못했어요" 카드 노출 (GH-96)
    case migrationNotice = "migration_notice"
    /// 이전 실패 카드 [다시 시도] (GH-96)
    case migrationRetry = "migration_retry"
    /// 이전 실패 카드 [문의하기] (GH-96)
    case migrationContact = "migration_contact"
    /// 상세 일지 "＋ 남기기"·"＋ 오늘 한 줄 남기기" (GH-95)
    case addJournal = "add_journal"
    /// 일지 시트 "남기기" 저장 성공 (GH-95)
    case saveJournal = "save_journal"
    /// 상세 일지 "모두 보기" (GH-95)
    case viewAllJournals = "view_all_journals"
    /// 아이패드 사이드바 항목 (+type: category·finished·badge·map·settings) (GH-99)
    case sidebarItem = "sidebar_item"
    /// 아이패드 레이아웃으로 처음 보일 때 (+type: three_column·two_column) (GH-99)
    case padLayout = "pad_layout"
}
