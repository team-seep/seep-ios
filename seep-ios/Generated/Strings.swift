// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum Strings {
  /// 하고 싶어요
  internal static let categoryWantToDo = Strings.tr("Localization", "category_want_to_do", fallback: "하고 싶어요")
  /// 갖고 싶어요
  internal static let categoryWantToGet = Strings.tr("Localization", "category_want_to_get", fallback: "갖고 싶어요")
  /// 가고 싶어요
  internal static let categoryWantToGo = Strings.tr("Localization", "category_want_to_go", fallback: "가고 싶어요")
  /// 취소
  internal static let commonCancel = Strings.tr("Localization", "common_cancel", fallback: "취소")
  /// 하고 싶어요
  internal static let commonCategoryWantToDo = Strings.tr("Localization", "common_category_want_to_do", fallback: "하고 싶어요")
  /// 갖고 싶어요
  internal static let commonCategoryWantToGet = Strings.tr("Localization", "common_category_want_to_get", fallback: "갖고 싶어요")
  /// 가고 싶어요
  internal static let commonCategoryWantToGo = Strings.tr("Localization", "common_category_want_to_go", fallback: "가고 싶어요")
  /// 확인
  internal static let commonOk = Strings.tr("Localization", "common_ok", fallback: "확인")
  /// 취소하기
  internal static let detailActionSheetCancel = Strings.tr("Localization", "detail_action_sheet_cancel", fallback: "취소하기")
  /// 완료 취소하기
  internal static let detailActionSheetCancelFinish = Strings.tr("Localization", "detail_action_sheet_cancel_finish", fallback: "완료 취소하기")
  /// 삭제하기
  internal static let detailActionSheetDelete = Strings.tr("Localization", "detail_action_sheet_delete", fallback: "삭제하기")
  /// 공유하기
  internal static let detailActionSheetShare = Strings.tr("Localization", "detail_action_sheet_share", fallback: "공유하기")
  /// 취소시 다시 메인 홈에서
  /// 확인할 수 있습니다!
  internal static let detailCancelFinishDescription = Strings.tr("Localization", "detail_cancel_finish_description", fallback: "취소시 다시 메인 홈에서\n확인할 수 있습니다!")
  /// 아니요
  internal static let detailCancelFinishNo = Strings.tr("Localization", "detail_cancel_finish_no", fallback: "아니요")
  /// 취소할래요
  internal static let detailCancelFinishOk = Strings.tr("Localization", "detail_cancel_finish_ok", fallback: "취소할래요")
  /// 완료된 항목을 취소할까요?
  internal static let detailCancelFinishTitle = Strings.tr("Localization", "detail_cancel_finish_title", fallback: "완료된 항목을 취소할까요?")
  /// 삭제하면 복원이 안되요😭
  /// 지워도 될까요?
  internal static let detailDeleteMessage = Strings.tr("Localization", "detail_delete_message", fallback: "삭제하면 복원이 안되요😭\n지워도 될까요?")
  /// 커리어
  internal static let hashtagCareer = Strings.tr("Localization", "hashtag_career", fallback: "커리어")
  /// 데이트
  internal static let hashtagDate = Strings.tr("Localization", "hashtag_date", fallback: "데이트")
  /// 취미
  internal static let hashtagHobby = Strings.tr("Localization", "hashtag_hobby", fallback: "취미")
  /// 여가생활
  internal static let hashtagLeisure = Strings.tr("Localization", "hashtag_leisure", fallback: "여가생활")
  /// 일상
  internal static let hashtagLife = Strings.tr("Localization", "hashtag_life", fallback: "일상")
  /// 쇼핑
  internal static let hashtagShopping = Strings.tr("Localization", "hashtag_shopping", fallback: "쇼핑")
  /// 스포츠
  internal static let hashtagSports = Strings.tr("Localization", "hashtag_sports", fallback: "스포츠")
  /// 주식
  internal static let hashtagStock = Strings.tr("Localization", "hashtag_stock", fallback: "주식")
  /// 여행
  internal static let hashtagTrip = Strings.tr("Localization", "hashtag_trip", fallback: "여행")
  /// 먼훗날
  internal static let homeInFarFurture = Strings.tr("Localization", "home_in_far_furture", fallback: "먼훗날")
  /// 일정없음
  internal static let homeNoDeanline = Strings.tr("Localization", "home_no_deanline", fallback: "일정없음")
  /// ✔️ 저장
  internal static let notificationAdd = Strings.tr("Localization", "notification_add", fallback: "✔️ 저장")
  /// 알림 추가
  internal static let notificationAddTitle = Strings.tr("Localization", "notification_add_title", fallback: "알림 추가")
  /// '%@' 하기로 한 것 잊지 않으셨나요?
  internal static func notificationBodyFormat(_ p1: Any) -> String {
    return Strings.tr("Localization", "notification_body_format", String(describing: p1), fallback: "'%@' 하기로 한 것 잊지 않으셨나요?")
  }
  /// 알림 날짜
  internal static let notificationDate = Strings.tr("Localization", "notification_date", fallback: "알림 날짜")
  /// 알림 수정
  internal static let notificationEditTitle = Strings.tr("Localization", "notification_edit_title", fallback: "알림 수정")
  /// 알림 시간
  internal static let notificationTime = Strings.tr("Localization", "notification_time", fallback: "알림 시간")
  /// 🔔 여기보세요👀
  internal static let notificationTitle = Strings.tr("Localization", "notification_title", fallback: "🔔 여기보세요👀")
  /// 1일 전
  internal static let notificationTypeBeforeDay = Strings.tr("Localization", "notification_type_before_day", fallback: "1일 전")
  /// 2일 전
  internal static let notificationTypeBeforeTwoDay = Strings.tr("Localization", "notification_type_before_two_day", fallback: "2일 전")
  /// 일주일 전
  internal static let notificationTypeBeforeWeek = Strings.tr("Localization", "notification_type_before_week", fallback: "일주일 전")
  /// 매일
  internal static let notificationTypeEveryday = Strings.tr("Localization", "notification_type_everyday", fallback: "매일")
  /// 당일
  internal static let notificationTypeTargatDay = Strings.tr("Localization", "notification_type_targat_day", fallback: "당일")
  /// 🏞 사진
  internal static let sharePhotoAlbum = Strings.tr("Localization", "share_photo_album", fallback: "🏞 사진")
  /// 👌 이렇게 공유할래요
  internal static let sharePhotoButton = Strings.tr("Localization", "share_photo_button", fallback: "👌 이렇게 공유할래요")
  /// 원하는 사진으로 공유하기 위해 앨범 접근 권한이 필요해요.
  internal static let sharePhotoDenyMessage = Strings.tr("Localization", "share_photo_deny_message", fallback: "원하는 사진으로 공유하기 위해 앨범 접근 권한이 필요해요.")
  /// 닫기
  internal static let sharePhotoDismiss = Strings.tr("Localization", "share_photo_dismiss", fallback: "닫기")
  /// 😀 이모지
  internal static let sharePhotoEmoji = Strings.tr("Localization", "share_photo_emoji", fallback: "😀 이모지")
  /// 공유하기
  internal static let sharePhotoTitle = Strings.tr("Localization", "share_photo_title", fallback: "공유하기")
  /// 👆화면을 두번 탭하면 텍스트 컬러를 바꿀 수 있어요
  internal static let sharePhotoTooltip = Strings.tr("Localization", "share_photo_tooltip", fallback: "👆화면을 두번 탭하면 텍스트 컬러를 바꿀 수 있어요")
  /// GH-63 스플래시
  internal static let splashTagline = Strings.tr("Localization", "splash_tagline", fallback: "진짜 나를 위해 하고 싶은 것")
  /// 알림 추가
  internal static let writeAddNotification = Strings.tr("Localization", "write_add_notification", fallback: "알림 추가")
  /// 📍날짜를 선택해주세요!
  internal static let writeErrorDateEmpty = Strings.tr("Localization", "write_error_date_empty", fallback: "📍날짜를 선택해주세요!")
  /// 📍해시태그는 7자내로 작성해주세요!
  internal static let writeErrorMaxLengthHashtag = Strings.tr("Localization", "write_error_max_length_hashtag", fallback: "📍해시태그는 7자내로 작성해주세요!")
  /// 📍메모는 300자내로 작성해주세요!
  internal static let writeErrorMaxLengthMemo = Strings.tr("Localization", "write_error_max_length_memo", fallback: "📍메모는 300자내로 작성해주세요!")
  /// 📍제목은 18자내로 작성해주세요!
  internal static let writeErrorMaxLengthTitle = Strings.tr("Localization", "write_error_max_length_title", fallback: "📍제목은 18자내로 작성해주세요!")
  /// 📍제목을 작성해주세요!
  internal static let writeErrorTitleEmpty = Strings.tr("Localization", "write_error_title_empty", fallback: "📍제목을 작성해주세요!")
  /// 메모
  internal static let writeHeaderMemo = Strings.tr("Localization", "write_header_memo", fallback: "메모")
  /// 제목
  internal static let writeHeaderTitle = Strings.tr("Localization", "write_header_title", fallback: "제목")
  /// + 새로운 태그
  internal static let writePlaceholderHashtag = Strings.tr("Localization", "write_placeholder_hashtag", fallback: "+ 새로운 태그")
  /// 뭐 하고 싶어요?
  internal static let writePlaceholderTitleCategoryWantToDo = Strings.tr("Localization", "write_placeholder_title_category_want_to_do", fallback: "뭐 하고 싶어요?")
  /// 뭐 갖고 싶어요?
  internal static let writePlaceholderTitleCategoryWantToGet = Strings.tr("Localization", "write_placeholder_title_category_want_to_get", fallback: "뭐 갖고 싶어요?")
  /// 어디 가고 싶어요?
  internal static let writePlaceholderTitleCategoryWantToGo = Strings.tr("Localization", "write_placeholder_title_category_want_to_go", fallback: "어디 가고 싶어요?")
  internal enum AppLock {
    /// 싶 잠금을 확인할게요
    internal static let reason = Strings.tr("Localization", "app_lock.reason", fallback: "싶 잠금을 확인할게요")
    internal enum Biometry {
      /// Face ID
      internal static let faceId = Strings.tr("Localization", "app_lock.biometry.face_id", fallback: "Face ID")
      /// 기기 암호
      internal static let passcode = Strings.tr("Localization", "app_lock.biometry.passcode", fallback: "기기 암호")
      /// Touch ID
      internal static let touchId = Strings.tr("Localization", "app_lock.biometry.touch_id", fallback: "Touch ID")
    }
    internal enum Screen {
      /// %@로 확인하면 열려요
      internal static func descriptionFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "app_lock.screen.description_format", String(describing: p1), fallback: "%@로 확인하면 열려요")
      }
      /// 싶이 잠겨 있어요
      internal static let title = Strings.tr("Localization", "app_lock.screen.title", fallback: "싶이 잠겨 있어요")
      /// 잠겨 있어요
      internal static let titleBold = Strings.tr("Localization", "app_lock.screen.title_bold", fallback: "잠겨 있어요")
      /// %@로 열기
      internal static func unlockButtonFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "app_lock.screen.unlock_button_format", String(describing: p1), fallback: "%@로 열기")
      }
    }
    internal enum Sheet {
      /// 닫기
      internal static let close = Strings.tr("Localization", "app_lock.sheet.close", fallback: "닫기")
      /// 잠금 끄기
      internal static let disableButton = Strings.tr("Localization", "app_lock.sheet.disable_button", fallback: "잠금 끄기")
      /// 잠금을 끄면 앱을 열 때 더 묻지 않아요.
      /// 끄기 전에 한 번 더 확인할게요.
      internal static let disableDescription = Strings.tr("Localization", "app_lock.sheet.disable_description", fallback: "잠금을 끄면 앱을 열 때 더 묻지 않아요.\n끄기 전에 한 번 더 확인할게요.")
      /// 지금 싶이
      /// 잠겨 있어요
      internal static let disableTitle = Strings.tr("Localization", "app_lock.sheet.disable_title", fallback: "지금 싶이\n잠겨 있어요")
      /// 잠겨 있어요
      internal static let disableTitleBold = Strings.tr("Localization", "app_lock.sheet.disable_title_bold", fallback: "잠겨 있어요")
      /// %@로 잠그기
      internal static func enableButtonFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "app_lock.sheet.enable_button_format", String(describing: p1), fallback: "%@로 잠그기")
      }
      /// 앱을 열 때 %@나 기기 암호를 물어봐요.
      /// 홈 화면 위젯은 잠금과 상관없이 보여요.
      internal static func enableDescriptionFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "app_lock.sheet.enable_description_format", String(describing: p1), fallback: "앱을 열 때 %@나 기기 암호를 물어봐요.\n홈 화면 위젯은 잠금과 상관없이 보여요.")
      }
      /// 앱을 열 때 기기 암호를 물어봐요.
      /// 홈 화면 위젯은 잠금과 상관없이 보여요.
      internal static let enableDescriptionPasscode = Strings.tr("Localization", "app_lock.sheet.enable_description_passcode", fallback: "앱을 열 때 기기 암호를 물어봐요.\n홈 화면 위젯은 잠금과 상관없이 보여요.")
      /// 싶을 나만 볼 수 있게
      /// 잠가둘까요?
      internal static let enableTitle = Strings.tr("Localization", "app_lock.sheet.enable_title", fallback: "싶을 나만 볼 수 있게\n잠가둘까요?")
      /// 잠가둘까요?
      internal static let enableTitleBold = Strings.tr("Localization", "app_lock.sheet.enable_title_bold", fallback: "잠가둘까요?")
      /// 다음에 할게요
      internal static let later = Strings.tr("Localization", "app_lock.sheet.later", fallback: "다음에 할게요")
    }
    internal enum Toast {
      /// 기기 암호를 먼저 설정해 주세요
      internal static let noPasscode = Strings.tr("Localization", "app_lock.toast.no_passcode", fallback: "기기 암호를 먼저 설정해 주세요")
    }
  }
  internal enum Badge {
    /// D-day
    internal static let dday = Strings.tr("Localization", "badge.dday", fallback: "D-day")
    /// %d / %d
    internal static func progressFormat(_ p1: Int, _ p2: Int) -> String {
      return Strings.tr("Localization", "badge.progress_format", p1, p2, fallback: "%d / %d")
    }
    internal enum Celebration {
      /// %@ · %@
      internal static func cardDescriptionFormat(_ p1: Any, _ p2: Any) -> String {
        return Strings.tr("Localization", "badge.celebration.card_description_format", String(describing: p1), String(describing: p2), fallback: "%@ · %@")
      }
      /// 좋아요
      internal static let confirm = Strings.tr("Localization", "badge.celebration.confirm", fallback: "좋아요")
      /// 새 배지를 받았어요
      internal static let titleBold = Strings.tr("Localization", "badge.celebration.title_bold", fallback: "새 배지를 받았어요")
      /// 위시를 %d개나 이뤘어요!
      /// 새 배지를 받았어요
      internal static func titleFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "badge.celebration.title_format", p1, fallback: "위시를 %d개나 이뤘어요!\n새 배지를 받았어요")
      }
      /// 배지 모아보기
      internal static let viewBadges = Strings.tr("Localization", "badge.celebration.view_badges", fallback: "배지 모아보기")
    }
    internal enum Collection {
      /// 위시를 이룰 때마다 하나씩 열려요
      internal static let description = Strings.tr("Localization", "badge.collection.description", fallback: "위시를 이룰 때마다 하나씩 열려요")
      /// 를 모았어요!
      internal static let titleBold = Strings.tr("Localization", "badge.collection.title_bold", fallback: "를 모았어요!")
      /// 이룬 싶이 모여
      /// 배지 %d개를 모았어요!
      internal static func titleFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "badge.collection.title_format", p1, fallback: "이룬 싶이 모여\n배지 %d개를 모았어요!")
      }
      /// %d개
      internal static func titleHighlightFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "badge.collection.title_highlight_format", p1, fallback: "%d개")
      }
    }
    internal enum Condition {
      /// 위시 %d개 이루기
      internal static func finishFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "badge.condition.finish_format", p1, fallback: "위시 %d개 이루기")
      }
      /// 하고 싶은 것 1개 이루기
      internal static let firstWantToDo = Strings.tr("Localization", "badge.condition.first_want_to_do", fallback: "하고 싶은 것 1개 이루기")
      /// 갖고 싶은 것 1개 이루기
      internal static let firstWantToGet = Strings.tr("Localization", "badge.condition.first_want_to_get", fallback: "갖고 싶은 것 1개 이루기")
      /// 가고 싶은 곳 1개 이루기
      internal static let firstWantToGo = Strings.tr("Localization", "badge.condition.first_want_to_go", fallback: "가고 싶은 곳 1개 이루기")
      /// 마감일까지 이루기
      internal static let onTime = Strings.tr("Localization", "badge.condition.on_time", fallback: "마감일까지 이루기")
    }
    internal enum Name {
      /// 첫 싶
      internal static let finish1 = Strings.tr("Localization", "badge.name.finish_1", fallback: "첫 싶")
      /// 열 번째 싶
      internal static let finish10 = Strings.tr("Localization", "badge.name.finish_10", fallback: "열 번째 싶")
      /// 서른 번째 싶
      internal static let finish30 = Strings.tr("Localization", "badge.name.finish_30", fallback: "서른 번째 싶")
      /// 다섯 번째 싶
      internal static let finish5 = Strings.tr("Localization", "badge.name.finish_5", fallback: "다섯 번째 싶")
      /// 첫 하고 싶어요
      internal static let firstWantToDo = Strings.tr("Localization", "badge.name.first_want_to_do", fallback: "첫 하고 싶어요")
      /// 첫 갖고 싶어요
      internal static let firstWantToGet = Strings.tr("Localization", "badge.name.first_want_to_get", fallback: "첫 갖고 싶어요")
      /// 첫 가고 싶어요
      internal static let firstWantToGo = Strings.tr("Localization", "badge.name.first_want_to_go", fallback: "첫 가고 싶어요")
      /// 약속 지킴이
      internal static let onTime = Strings.tr("Localization", "badge.name.on_time", fallback: "약속 지킴이")
    }
  }
  internal enum Common {
    /// %@원
    internal static func wonFormat(_ p1: Any) -> String {
      return Strings.tr("Localization", "common.won_format", String(describing: p1), fallback: "%@원")
    }
    /// 원
    internal static let wonUnit = Strings.tr("Localization", "common.won_unit", fallback: "원")
  }
  internal enum ControlGuide {
    /// 제어 센터 · 단축어로 적기
    internal static let title = Strings.tr("Localization", "control_guide.title", fallback: "제어 센터 · 단축어로 적기")
    internal enum Control {
      /// "싶 적기" 컨트롤을 두면 앱을 찾지 않고 바로 작성 화면을 열어요.
      internal static let description = Strings.tr("Localization", "control_guide.control.description", fallback: "\"싶 적기\" 컨트롤을 두면 앱을 찾지 않고 바로 작성 화면을 열어요.")
      /// 제어 센터를 열고 왼쪽 위 ＋를 눌러요.
      internal static let step1 = Strings.tr("Localization", "control_guide.control.step1", fallback: "제어 센터를 열고 왼쪽 위 ＋를 눌러요.")
      /// 제어 항목 추가에서 "싶 적기"를 찾아 놓아요.
      internal static let step2 = Strings.tr("Localization", "control_guide.control.step2", fallback: "제어 항목 추가에서 \"싶 적기\"를 찾아 놓아요.")
      /// 컨트롤을 길게 눌러 카테고리를 고를 수 있어요.
      internal static let step3 = Strings.tr("Localization", "control_guide.control.step3", fallback: "컨트롤을 길게 눌러 카테고리를 고를 수 있어요.")
      /// 제어 센터 · 잠금화면 · 동작 버튼
      internal static let title = Strings.tr("Localization", "control_guide.control.title", fallback: "제어 센터 · 잠금화면 · 동작 버튼")
    }
    internal enum Shortcut {
      /// 단축어 앱이나 Siri로도 바로 적을 수 있어요.
      internal static let description = Strings.tr("Localization", "control_guide.shortcut.description", fallback: "단축어 앱이나 Siri로도 바로 적을 수 있어요.")
      /// 단축어 앱에서 ＋를 눌러 새 단축어를 만들어요.
      internal static let step1 = Strings.tr("Localization", "control_guide.shortcut.step1", fallback: "단축어 앱에서 ＋를 눌러 새 단축어를 만들어요.")
      /// 동작 검색에서 "싶"을 찾아 "싶 적기"를 추가해요.
      internal static let step2 = Strings.tr("Localization", "control_guide.shortcut.step2", fallback: "동작 검색에서 \"싶\"을 찾아 \"싶 적기\"를 추가해요.")
      /// Siri에게 "싶 적기"라고 말해도 돼요.
      internal static let step3 = Strings.tr("Localization", "control_guide.shortcut.step3", fallback: "Siri에게 \"싶 적기\"라고 말해도 돼요.")
      /// 단축어 · Siri
      internal static let title = Strings.tr("Localization", "control_guide.shortcut.title", fallback: "단축어 · Siri")
    }
  }
  internal enum Detail {
    internal enum Calendar {
      /// 캘린더에 추가
      internal static let add = Strings.tr("Localization", "detail.calendar.add", fallback: "캘린더에 추가")
      /// 캘린더에 추가됨
      internal static let added = Strings.tr("Localization", "detail.calendar.added", fallback: "캘린더에 추가됨")
      internal enum AgainAlert {
        /// 추가하기
        internal static let confirm = Strings.tr("Localization", "detail.calendar.again_alert.confirm", fallback: "추가하기")
        /// 한 번 더 추가할까요?
        /// 캘린더에 같은 일정이 하나 더 생겨요.
        internal static let message = Strings.tr("Localization", "detail.calendar.again_alert.message", fallback: "한 번 더 추가할까요?\n캘린더에 같은 일정이 하나 더 생겨요.")
        /// 이미 캘린더에 추가했어요
        internal static let title = Strings.tr("Localization", "detail.calendar.again_alert.title", fallback: "이미 캘린더에 추가했어요")
      }
      internal enum DeniedAlert {
        /// 설정에서 캘린더 접근을 허용해주세요.
        internal static let message = Strings.tr("Localization", "detail.calendar.denied_alert.message", fallback: "설정에서 캘린더 접근을 허용해주세요.")
        /// 설정으로 이동
        internal static let settings = Strings.tr("Localization", "detail.calendar.denied_alert.settings", fallback: "설정으로 이동")
        /// 캘린더 접근을 허용하면 추가할 수 있어요
        internal static let title = Strings.tr("Localization", "detail.calendar.denied_alert.title", fallback: "캘린더 접근을 허용하면 추가할 수 있어요")
      }
      internal enum Error {
        /// 일정을 추가할 캘린더가 없어요.
        internal static let noDefaultCalendar = Strings.tr("Localization", "detail.calendar.error.no_default_calendar", fallback: "일정을 추가할 캘린더가 없어요.")
      }
      internal enum Toast {
        /// 👏 %@ 캘린더에 추가했어요!
        internal static func addedFormat(_ p1: Any) -> String {
          return Strings.tr("Localization", "detail.calendar.toast.added_format", String(describing: p1), fallback: "👏 %@ 캘린더에 추가했어요!")
        }
      }
    }
    internal enum Dday {
      /// %@이었어요
      internal static func pastFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "detail.dday.past_format", String(describing: p1), fallback: "%@이었어요")
      }
      /// D-Day
      internal static let today = Strings.tr("Localization", "detail.dday.today", fallback: "D-Day")
      /// %@까지
      internal static func untilFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "detail.dday.until_format", String(describing: p1), fallback: "%@까지")
      }
      /// 오늘까지
      internal static let untilToday = Strings.tr("Localization", "detail.dday.until_today", fallback: "오늘까지")
    }
    internal enum Letter {
      /// %@에 봉인했어요 · %d자
      internal static func sealedCaptionFormat(_ p1: Any, _ p2: Int) -> String {
        return Strings.tr("Localization", "detail.letter.sealed_caption_format", String(describing: p1), p2, fallback: "%@에 봉인했어요 · %d자")
      }
      /// 이루는 날 열려요
      internal static let sealedTitle = Strings.tr("Localization", "detail.letter.sealed_title", fallback: "이루는 날 열려요")
      /// 미래의 나에게
      internal static let title = Strings.tr("Localization", "detail.letter.title", fallback: "미래의 나에게")
      /// %@에 씀
      internal static func writtenFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "detail.letter.written_format", String(describing: p1), fallback: "%@에 씀")
      }
      internal enum RewriteAlert {
        /// 새로 쓰기
        internal static let confirm = Strings.tr("Localization", "detail.letter.rewrite_alert.confirm", fallback: "새로 쓰기")
        /// 이전 편지는 사라져요.
        internal static let message = Strings.tr("Localization", "detail.letter.rewrite_alert.message", fallback: "이전 편지는 사라져요.")
        /// 봉인한 편지를 새로 쓸까요?
        internal static let title = Strings.tr("Localization", "detail.letter.rewrite_alert.title", fallback: "봉인한 편지를 새로 쓸까요?")
      }
    }
    internal enum Link {
      /// 상품 링크 열기
      internal static let openAccessibility = Strings.tr("Localization", "detail.link.open_accessibility", fallback: "상품 링크 열기")
      /// 미리보기를 불러오지 못했어요. 탭하면 열 수 있어요
      internal static let previewFailed = Strings.tr("Localization", "detail.link.preview_failed", fallback: "미리보기를 불러오지 못했어요. 탭하면 열 수 있어요")
      /// 링크
      internal static let title = Strings.tr("Localization", "detail.link.title", fallback: "링크")
    }
    internal enum Meta {
      /// %@ 외 %d개
      internal static func notificationMoreFormat(_ p1: Any, _ p2: Int) -> String {
        return Strings.tr("Localization", "detail.meta.notification_more_format", String(describing: p1), p2, fallback: "%@ 외 %d개")
      }
    }
    internal enum Nav {
      /// 수정
      internal static let edit = Strings.tr("Localization", "detail.nav.edit", fallback: "수정")
      /// 더보기
      internal static let more = Strings.tr("Localization", "detail.nav.more", fallback: "더보기")
    }
    internal enum Photo {
      /// ＋ 사진 붙이기
      internal static let add = Strings.tr("Localization", "detail.photo.add", fallback: "＋ 사진 붙이기")
      /// 바꾸기
      internal static let change = Strings.tr("Localization", "detail.photo.change", fallback: "바꾸기")
      /// 사진 지우기
      internal static let delete = Strings.tr("Localization", "detail.photo.delete", fallback: "사진 지우기")
      /// 사진
      internal static let title = Strings.tr("Localization", "detail.photo.title", fallback: "사진")
      internal enum Error {
        /// 사진을 불러오지 못했어요. 다른 사진을 골라주세요.
        internal static let invalidImage = Strings.tr("Localization", "detail.photo.error.invalid_image", fallback: "사진을 불러오지 못했어요. 다른 사진을 골라주세요.")
        /// 사진을 저장하지 못했어요. 잠시 후 다시 시도해주세요.
        internal static let writeFailed = Strings.tr("Localization", "detail.photo.error.write_failed", fallback: "사진을 저장하지 못했어요. 잠시 후 다시 시도해주세요.")
      }
    }
    internal enum Place {
      /// 장소 지우기
      internal static let delete = Strings.tr("Localization", "detail.place.delete", fallback: "장소 지우기")
      /// 장소
      internal static let title = Strings.tr("Localization", "detail.place.title", fallback: "장소")
      internal enum Search {
        /// 장소 이름이나 주소로 찾아봐요. 위치 권한은 필요 없어요.
        internal static let caption = Strings.tr("Localization", "detail.place.search.caption", fallback: "장소 이름이나 주소로 찾아봐요. 위치 권한은 필요 없어요.")
        /// 검색어 지우기
        internal static let clear = Strings.tr("Localization", "detail.place.search.clear", fallback: "검색어 지우기")
        /// 찾는 장소가 없어요
        internal static let empty = Strings.tr("Localization", "detail.place.search.empty", fallback: "찾는 장소가 없어요")
        /// 장소 이름이나 주소
        internal static let placeholder = Strings.tr("Localization", "detail.place.search.placeholder", fallback: "장소 이름이나 주소")
        /// 어디로
        /// 가고 싶어요?
        internal static let title = Strings.tr("Localization", "detail.place.search.title", fallback: "어디로\n가고 싶어요?")
        /// 가고 싶어요?
        internal static let titleBold = Strings.tr("Localization", "detail.place.search.title_bold", fallback: "가고 싶어요?")
      }
    }
    internal enum Saving {
      /// 다 모았어요! 이제 겟할 시간이에요
      internal static let completed = Strings.tr("Localization", "detail.saving.completed", fallback: "다 모았어요! 이제 겟할 시간이에요")
      /// 기록 삭제
      internal static let delete = Strings.tr("Localization", "detail.saving.delete", fallback: "기록 삭제")
      /// +%@원
      internal static func recordFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "detail.saving.record_format", String(describing: p1), fallback: "+%@원")
      }
      /// %@원 더 모으면 돼요!
      internal static func remainingFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "detail.saving.remaining_format", String(describing: p1), fallback: "%@원 더 모으면 돼요!")
      }
      /// / %@원
      internal static func targetFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "detail.saving.target_format", String(describing: p1), fallback: "/ %@원")
      }
      internal enum DeleteAlert {
        /// 삭제
        internal static let confirm = Strings.tr("Localization", "detail.saving.delete_alert.confirm", fallback: "삭제")
        /// 이 기록을 삭제할까요?
        internal static let title = Strings.tr("Localization", "detail.saving.delete_alert.title", fallback: "이 기록을 삭제할까요?")
      }
      internal enum Sheet {
        /// 모은 금액
        internal static let amount = Strings.tr("Localization", "detail.saving.sheet.amount", fallback: "모은 금액")
        /// +10만
        internal static let plus100k = Strings.tr("Localization", "detail.saving.sheet.plus_100k", fallback: "+10만")
        /// +1만
        internal static let plus10k = Strings.tr("Localization", "detail.saving.sheet.plus_10k", fallback: "+1만")
        /// +5만
        internal static let plus50k = Strings.tr("Localization", "detail.saving.sheet.plus_50k", fallback: "+5만")
        /// %@원 / %@원
        internal static func previewAmountFormat(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localization", "detail.saving.sheet.preview_amount_format", String(describing: p1), String(describing: p2), fallback: "%@원 / %@원")
        }
        /// 기록하면 %@ (%d%%)
        internal static func previewFormat(_ p1: Any, _ p2: Int) -> String {
          return Strings.tr("Localization", "detail.saving.sheet.preview_format", String(describing: p1), p2, fallback: "기록하면 %@ (%d%%)")
        }
        /// 남은 금액 전부
        internal static let remainingAll = Strings.tr("Localization", "detail.saving.sheet.remaining_all", fallback: "남은 금액 전부")
        /// 기록하기
        internal static let save = Strings.tr("Localization", "detail.saving.sheet.save", fallback: "기록하기")
        /// 얼마나
        /// 모았어요?
        internal static let title = Strings.tr("Localization", "detail.saving.sheet.title", fallback: "얼마나\n모았어요?")
        /// 모았어요?
        internal static let titleBold = Strings.tr("Localization", "detail.saving.sheet.title_bold", fallback: "모았어요?")
      }
      internal enum Toast {
        /// 👏 목표 금액을 다 모았어요!
        internal static let completed = Strings.tr("Localization", "detail.saving.toast.completed", fallback: "👏 목표 금액을 다 모았어요!")
      }
    }
    internal enum Section {
      /// 열기
      internal static let linkOpen = Strings.tr("Localization", "detail.section.link_open", fallback: "열기")
      /// ＋ 장소 붙이기
      internal static let placeAdd = Strings.tr("Localization", "detail.section.place_add", fallback: "＋ 장소 붙이기")
      /// 변경
      internal static let placeChange = Strings.tr("Localization", "detail.section.place_change", fallback: "변경")
      /// 모은 돈
      internal static let savings = Strings.tr("Localization", "detail.section.savings", fallback: "모은 돈")
      /// ＋ 기록
      internal static let savingsAdd = Strings.tr("Localization", "detail.section.savings_add", fallback: "＋ 기록")
      /// %d/%d
      internal static func stepCountFormat(_ p1: Int, _ p2: Int) -> String {
        return Strings.tr("Localization", "detail.section.step_count_format", p1, p2, fallback: "%d/%d")
      }
    }
    internal enum Step {
      /// 삭제
      internal static let delete = Strings.tr("Localization", "detail.step.delete", fallback: "삭제")
      /// 단계
      internal static let title = Strings.tr("Localization", "detail.step.title", fallback: "단계")
      internal enum AddAlert {
        /// 추가
        internal static let confirm = Strings.tr("Localization", "detail.step.add_alert.confirm", fallback: "추가")
        /// 예) 날짜 정하기
        internal static let placeholder = Strings.tr("Localization", "detail.step.add_alert.placeholder", fallback: "예) 날짜 정하기")
        /// 단계 추가
        internal static let title = Strings.tr("Localization", "detail.step.add_alert.title", fallback: "단계 추가")
      }
      internal enum Toast {
        /// 📍단계는 10개까지 추가할 수 있어요!
        internal static let maxCount = Strings.tr("Localization", "detail.step.toast.max_count", fallback: "📍단계는 10개까지 추가할 수 있어요!")
        /// 📍단계는 30자내로 작성해주세요!
        internal static let maxLength = Strings.tr("Localization", "detail.step.toast.max_length", fallback: "📍단계는 30자내로 작성해주세요!")
      }
    }
  }
  internal enum EmojiPicker {
    /// 최근 사용
    internal static let recent = Strings.tr("Localization", "emoji_picker.recent", fallback: "최근 사용")
    /// 이모지 고르기
    internal static let title = Strings.tr("Localization", "emoji_picker.title", fallback: "이모지 고르기")
    internal enum Category {
      /// 활동
      internal static let activities = Strings.tr("Localization", "emoji_picker.category.activities", fallback: "활동")
      /// 동물
      internal static let animals = Strings.tr("Localization", "emoji_picker.category.animals", fallback: "동물")
      /// 깃발
      internal static let flags = Strings.tr("Localization", "emoji_picker.category.flags", fallback: "깃발")
      /// 음식
      internal static let food = Strings.tr("Localization", "emoji_picker.category.food", fallback: "음식")
      /// 사물
      internal static let objects = Strings.tr("Localization", "emoji_picker.category.objects", fallback: "사물")
      /// 사람
      internal static let people = Strings.tr("Localization", "emoji_picker.category.people", fallback: "사람")
      /// 표정
      internal static let smileys = Strings.tr("Localization", "emoji_picker.category.smileys", fallback: "표정")
      /// 기호
      internal static let symbols = Strings.tr("Localization", "emoji_picker.category.symbols", fallback: "기호")
      /// 여행
      internal static let travel = Strings.tr("Localization", "emoji_picker.category.travel", fallback: "여행")
    }
  }
  internal enum Finished {
    /// 모였어요!
    internal static let headlineBold = Strings.tr("Localization", "finished.headline_bold", fallback: "모였어요!")
    /// %d개
    internal static func headlineCountFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "finished.headline_count_format", p1, fallback: "%d개")
    }
    /// 아직 이룬 싶이 없어요
    /// 하나씩 체크해봐요!
    internal static let headlineEmpty = Strings.tr("Localization", "finished.headline_empty", fallback: "아직 이룬 싶이 없어요\n하나씩 체크해봐요!")
    /// 하나씩 체크해봐요!
    internal static let headlineEmptyBold = Strings.tr("Localization", "finished.headline_empty_bold", fallback: "하나씩 체크해봐요!")
    /// GH-64 이룬 싶·설정
    internal static func headlineFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "finished.headline_format", p1, fallback: "지금까지 이룬 싶이\n%d개 모였어요!")
    }
    /// %@년 %d월
    internal static func monthFormat(_ p1: Any, _ p2: Int) -> String {
      return Strings.tr("Localization", "finished.month_format", String(describing: p1), p2, fallback: "%@년 %d월")
    }
    /// 이룬 싶 검색
    internal static let search = Strings.tr("Localization", "finished.search", fallback: "이룬 싶 검색")
    internal enum BadgeCard {
      /// 모아보기 ›
      internal static let more = Strings.tr("Localization", "finished.badge_card.more", fallback: "모아보기 ›")
      /// 배지 %d/%d
      internal static func titleFormat(_ p1: Int, _ p2: Int) -> String {
        return Strings.tr("Localization", "finished.badge_card.title_format", p1, p2, fallback: "배지 %d/%d")
      }
    }
    internal enum Empty {
      /// 싶 탭에서 체크하면 여기 모여요
      internal static let description = Strings.tr("Localization", "finished.empty.description", fallback: "싶 탭에서 체크하면 여기 모여요")
      /// 이 카테고리에서 이룬 싶이 아직 없어요
      internal static let filtered = Strings.tr("Localization", "finished.empty.filtered", fallback: "이 카테고리에서 이룬 싶이 아직 없어요")
      /// 아직 이룬 싶이 없어요
      internal static let title = Strings.tr("Localization", "finished.empty.title", fallback: "아직 이룬 싶이 없어요")
    }
    internal enum Filter {
      /// 전체
      internal static let all = Strings.tr("Localization", "finished.filter.all", fallback: "전체")
      /// 하고
      internal static let wantToDo = Strings.tr("Localization", "finished.filter.want_to_do", fallback: "하고")
      /// 갖고
      internal static let wantToGet = Strings.tr("Localization", "finished.filter.want_to_get", fallback: "갖고")
      /// 가고
      internal static let wantToGo = Strings.tr("Localization", "finished.filter.want_to_go", fallback: "가고")
    }
    internal enum Row {
      /// %d일 이룸
      internal static func dayFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "finished.row.day_format", p1, fallback: "%d일 이룸")
      }
      /// “%@”
      internal static func noteFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "finished.row.note_format", String(describing: p1), fallback: "“%@”")
      }
    }
    internal enum YearReviewCard {
      /// 보기 ›
      internal static let more = Strings.tr("Localization", "finished.year_review_card.more", fallback: "보기 ›")
      /// %@년 이룬 싶 돌아보기
      internal static func titleFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "finished.year_review_card.title_format", String(describing: p1), fallback: "%@년 이룬 싶 돌아보기")
      }
    }
  }
  internal enum FutureLetter {
    /// %d/%d
    internal static func countFormat(_ p1: Int, _ p2: Int) -> String {
      return Strings.tr("Localization", "future_letter.count_format", p1, p2, fallback: "%d/%d")
    }
    /// 미래의 나에게 쓰는 편지
    internal static let field = Strings.tr("Localization", "future_letter.field", fallback: "미래의 나에게 쓰는 편지")
    /// 다음에 할게요
    internal static let later = Strings.tr("Localization", "future_letter.later", fallback: "다음에 할게요")
    /// 봉인하면 이 위시를 이룰 때까지 다시 볼 수 없어요
    internal static let notice = Strings.tr("Localization", "future_letter.notice", fallback: "봉인하면 이 위시를 이룰 때까지 다시 볼 수 없어요")
    /// 이 위시를 이룬 나에게 하고 싶은 말을 적어요
    internal static let placeholder = Strings.tr("Localization", "future_letter.placeholder", fallback: "이 위시를 이룬 나에게 하고 싶은 말을 적어요")
    /// 봉인하기
    internal static let seal = Strings.tr("Localization", "future_letter.seal", fallback: "봉인하기")
    /// 이루는 날의 나에게
    /// 편지를 남겨요
    internal static let title = Strings.tr("Localization", "future_letter.title", fallback: "이루는 날의 나에게\n편지를 남겨요")
    /// 편지를 남겨요
    internal static let titleBold = Strings.tr("Localization", "future_letter.title_bold", fallback: "편지를 남겨요")
  }
  internal enum Home {
    /// 배지 %d/%d 모아보기
    internal static func badgeLinkFormat(_ p1: Int, _ p2: Int) -> String {
      return Strings.tr("Localization", "home.badge_link_format", p1, p2, fallback: "배지 %d/%d 모아보기")
    }
    /// 삭제
    internal static let delete = Strings.tr("Localization", "home.delete", fallback: "삭제")
    /// 아직 등록된 것이 없네요.
    /// 아래 적기 버튼을 누르면 작성할 수 있어요!
    internal static let emptyTab = Strings.tr("Localization", "home.empty_tab", fallback: "아직 등록된 것이 없네요.\n아래 적기 버튼을 누르면 작성할 수 있어요!")
    /// 완료하기
    internal static let finishAccessibility = Strings.tr("Localization", "home.finish_accessibility", fallback: "완료하기")
    /// 완료됨
    internal static let finishedAccessibility = Strings.tr("Localization", "home.finished_accessibility", fallback: "완료됨")
    /// %d/%d
    internal static func stepProgressFormat(_ p1: Int, _ p2: Int) -> String {
      return Strings.tr("Localization", "home.step_progress_format", p1, p2, fallback: "%d/%d")
    }
    internal enum EmptyTitle {
      /// 하고 싶은 것들을
      /// 적어봐요!
      internal static let wantToDo = Strings.tr("Localization", "home.empty_title.want_to_do", fallback: "하고 싶은 것들을\n적어봐요!")
      /// 갖고 싶은 것들을
      /// 적어봐요!
      internal static let wantToGet = Strings.tr("Localization", "home.empty_title.want_to_get", fallback: "갖고 싶은 것들을\n적어봐요!")
      /// 가고 싶은 장소를
      /// 적어봐요!
      internal static let wantToGo = Strings.tr("Localization", "home.empty_title.want_to_go", fallback: "가고 싶은 장소를\n적어봐요!")
    }
    internal enum ErrorAlert {
      /// 확인
      internal static let confirm = Strings.tr("Localization", "home.error_alert.confirm", fallback: "확인")
    }
    internal enum Filter {
      /// 가고 싶은 곳 지도
      internal static let placeMap = Strings.tr("Localization", "home.filter.place_map", fallback: "가고 싶은 곳 지도")
      /// 정렬 바꾸기
      internal static let sortAccessibility = Strings.tr("Localization", "home.filter.sort_accessibility", fallback: "정렬 바꾸기")
      /// 고르면 홈에서 끌어서 순서를 바꿀 수 있어요
      internal static let sortCaption = Strings.tr("Localization", "home.filter.sort_caption", fallback: "고르면 홈에서 끌어서 순서를 바꿀 수 있어요")
      /// 그리드로 보기
      internal static let viewTypeGrid = Strings.tr("Localization", "home.filter.view_type_grid", fallback: "그리드로 보기")
      /// 리스트로 보기
      internal static let viewTypeList = Strings.tr("Localization", "home.filter.view_type_list", fallback: "리스트로 보기")
      internal enum Sort {
        /// 완료일 가까운순
        internal static let deadline = Strings.tr("Localization", "home.filter.sort.deadline", fallback: "완료일 가까운순")
        /// 최근 생성순
        internal static let latest = Strings.tr("Localization", "home.filter.sort.latest", fallback: "최근 생성순")
        /// 내가 정한 순서
        internal static let manual = Strings.tr("Localization", "home.filter.sort.manual", fallback: "내가 정한 순서")
      }
    }
    internal enum FinishNote {
      /// “%@”
      internal static func cellFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "home.finish_note.cell_format", String(describing: p1), fallback: "“%@”")
      }
      /// %d/%d
      internal static func countFormat(_ p1: Int, _ p2: Int) -> String {
        return Strings.tr("Localization", "home.finish_note.count_format", p1, p2, fallback: "%d/%d")
      }
      /// 지금 기분을 한 줄로 남겨두면 나중에 다시 볼 수 있어요.
      internal static let description = Strings.tr("Localization", "home.finish_note.description", fallback: "지금 기분을 한 줄로 남겨두면 나중에 다시 볼 수 있어요.")
      /// 완료 소감
      internal static let field = Strings.tr("Localization", "home.finish_note.field", fallback: "완료 소감")
      /// %@ · %@에 씀
      internal static func letterCardFormat(_ p1: Any, _ p2: Any) -> String {
        return Strings.tr("Localization", "home.finish_note.letter_card_format", String(describing: p1), String(describing: p2), fallback: "%@ · %@에 씀")
      }
      /// 이루고 나니 어때요?
      internal static let letterQuestion = Strings.tr("Localization", "home.finish_note.letter_question", fallback: "이루고 나니 어때요?")
      /// 편지를 보냈어요
      internal static let letterTitleBold = Strings.tr("Localization", "home.finish_note.letter_title_bold", fallback: "편지를 보냈어요")
      /// %d일 전의 내가
      /// 편지를 보냈어요
      internal static func letterTitleFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.finish_note.letter_title_format", p1, fallback: "%d일 전의 내가\n편지를 보냈어요")
      }
      /// 오늘의 내가
      /// 편지를 보냈어요
      internal static let letterTitleToday = Strings.tr("Localization", "home.finish_note.letter_title_today", fallback: "오늘의 내가\n편지를 보냈어요")
      /// 예) 생각보다 훨씬 좋았어요!
      internal static let placeholder = Strings.tr("Localization", "home.finish_note.placeholder", fallback: "예) 생각보다 훨씬 좋았어요!")
      /// 남기기
      internal static let save = Strings.tr("Localization", "home.finish_note.save", fallback: "남기기")
      /// 다음에 할게요
      internal static let skip = Strings.tr("Localization", "home.finish_note.skip", fallback: "다음에 할게요")
      /// 이루고 나니 어때요?
      internal static let titleBold = Strings.tr("Localization", "home.finish_note.title_bold", fallback: "이루고 나니 어때요?")
      /// %@,
      /// 이루고 나니 어때요?
      internal static func titleFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "home.finish_note.title_format", String(describing: p1), fallback: "%@,\n이루고 나니 어때요?")
      }
    }
    internal enum Pin {
      /// 고정은 3개까지 할 수 있어요
      internal static let limitToast = Strings.tr("Localization", "home.pin.limit_toast", fallback: "고정은 3개까지 할 수 있어요")
      /// 맨 위에 고정
      internal static let pin = Strings.tr("Localization", "home.pin.pin", fallback: "맨 위에 고정")
      /// 고정 해제
      internal static let unpin = Strings.tr("Localization", "home.pin.unpin", fallback: "고정 해제")
    }
    internal enum Reorder {
      /// 순서 바꾸기
      internal static let button = Strings.tr("Localization", "home.reorder.button", fallback: "순서 바꾸기")
      /// 완료
      internal static let done = Strings.tr("Localization", "home.reorder.done", fallback: "완료")
      /// 오른쪽 손잡이를 끌어서 옮겨요
      internal static let guide = Strings.tr("Localization", "home.reorder.guide", fallback: "오른쪽 손잡이를 끌어서 옮겨요")
      /// 고정한 위시는 맨 위에 있어요
      internal static let pinnedCaption = Strings.tr("Localization", "home.reorder.pinned_caption", fallback: "고정한 위시는 맨 위에 있어요")
      /// 순서를 바꾸고 있어요
      internal static let titleBold = Strings.tr("Localization", "home.reorder.title_bold", fallback: "순서를 바꾸고 있어요")
      internal enum Title {
        /// 하고 싶은 것들의
        /// 순서를 바꾸고 있어요
        internal static let wantToDo = Strings.tr("Localization", "home.reorder.title.want_to_do", fallback: "하고 싶은 것들의\n순서를 바꾸고 있어요")
        /// 갖고 싶은 것들의
        /// 순서를 바꾸고 있어요
        internal static let wantToGet = Strings.tr("Localization", "home.reorder.title.want_to_get", fallback: "갖고 싶은 것들의\n순서를 바꾸고 있어요")
        /// 가고 싶은 장소의
        /// 순서를 바꾸고 있어요
        internal static let wantToGo = Strings.tr("Localization", "home.reorder.title.want_to_go", fallback: "가고 싶은 장소의\n순서를 바꾸고 있어요")
      }
    }
    internal enum Search {
      /// 위시 검색
      internal static let accessibility = Strings.tr("Localization", "home.search.accessibility", fallback: "위시 검색")
    }
    internal enum Select {
      /// 전체 선택
      internal static let all = Strings.tr("Localization", "home.select.all", fallback: "전체 선택")
      /// 선택
      internal static let button = Strings.tr("Localization", "home.select.button", fallback: "선택")
      /// 취소
      internal static let cancel = Strings.tr("Localization", "home.select.cancel", fallback: "취소")
      /// %d개 선택됨
      internal static func countFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.select.count_format", p1, fallback: "%d개 선택됨")
      }
      /// %d개 삭제
      internal static func deleteFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.select.delete_format", p1, fallback: "%d개 삭제")
      }
      /// 골라서 지워요
      internal static let titleBold = Strings.tr("Localization", "home.select.title_bold", fallback: "골라서 지워요")
      internal enum DeleteAlert {
        /// 삭제
        internal static let confirm = Strings.tr("Localization", "home.select.delete_alert.confirm", fallback: "삭제")
        /// 삭제한 위시는 되돌릴 수 없어요.
        /// 예약한 알림도 함께 사라져요.
        internal static let message = Strings.tr("Localization", "home.select.delete_alert.message", fallback: "삭제한 위시는 되돌릴 수 없어요.\n예약한 알림도 함께 사라져요.")
        /// %d개의 위시를 삭제할까요?
        internal static func titleFormat(_ p1: Int) -> String {
          return Strings.tr("Localization", "home.select.delete_alert.title_format", p1, fallback: "%d개의 위시를 삭제할까요?")
        }
      }
      internal enum Title {
        /// 하고 싶은 것들을
        /// 골라서 지워요
        internal static let wantToDo = Strings.tr("Localization", "home.select.title.want_to_do", fallback: "하고 싶은 것들을\n골라서 지워요")
        /// 갖고 싶은 것들을
        /// 골라서 지워요
        internal static let wantToGet = Strings.tr("Localization", "home.select.title.want_to_get", fallback: "갖고 싶은 것들을\n골라서 지워요")
        /// 가고 싶은 장소를
        /// 골라서 지워요
        internal static let wantToGo = Strings.tr("Localization", "home.select.title.want_to_go", fallback: "가고 싶은 장소를\n골라서 지워요")
      }
    }
    internal enum SleepingWish {
      /// %d일째 그대로예요
      internal static func captionFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.sleeping_wish.caption_format", p1, fallback: "%d일째 그대로예요")
      }
      /// 이제 됐어요
      internal static let release = Strings.tr("Localization", "home.sleeping_wish.release", fallback: "이제 됐어요")
      internal enum Alert {
        /// 취소
        internal static let cancel = Strings.tr("Localization", "home.sleeping_wish.alert.cancel", fallback: "취소")
        /// 목록에서 지워지고 예약된 알림도 함께 사라져요.
        internal static let message = Strings.tr("Localization", "home.sleeping_wish.alert.message", fallback: "목록에서 지워지고 예약된 알림도 함께 사라져요.")
        /// 보내주기
        internal static let release = Strings.tr("Localization", "home.sleeping_wish.alert.release", fallback: "보내주기")
        /// 이 위시를 보내줄까요?
        internal static let title = Strings.tr("Localization", "home.sleeping_wish.alert.title", fallback: "이 위시를 보내줄까요?")
      }
      internal enum Keep {
        /// 여전히 하고 싶어요
        internal static let wantToDo = Strings.tr("Localization", "home.sleeping_wish.keep.want_to_do", fallback: "여전히 하고 싶어요")
        /// 여전히 갖고 싶어요
        internal static let wantToGet = Strings.tr("Localization", "home.sleeping_wish.keep.want_to_get", fallback: "여전히 갖고 싶어요")
        /// 여전히 가고 싶어요
        internal static let wantToGo = Strings.tr("Localization", "home.sleeping_wish.keep.want_to_go", fallback: "여전히 가고 싶어요")
      }
      internal enum Question {
        /// 아직 하고 싶어요?
        internal static let wantToDo = Strings.tr("Localization", "home.sleeping_wish.question.want_to_do", fallback: "아직 하고 싶어요?")
        /// 아직 갖고 싶어요?
        internal static let wantToGet = Strings.tr("Localization", "home.sleeping_wish.question.want_to_get", fallback: "아직 갖고 싶어요?")
        /// 아직 가고 싶어요?
        internal static let wantToGo = Strings.tr("Localization", "home.sleeping_wish.question.want_to_go", fallback: "아직 가고 싶어요?")
      }
      internal enum Toast {
        /// 좋아요! 두 달 뒤에 다시 물어볼게요
        internal static let keep = Strings.tr("Localization", "home.sleeping_wish.toast.keep", fallback: "좋아요! 두 달 뒤에 다시 물어볼게요")
        /// 위시를 보내줬어요
        internal static let release = Strings.tr("Localization", "home.sleeping_wish.toast.release", fallback: "위시를 보내줬어요")
      }
    }
    internal enum TitleFormat {
      /// 하고 싶은 것들이
      /// %d개 남았어요!
      internal static func wantToDo(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.title_format.want_to_do", p1, fallback: "하고 싶은 것들이\n%d개 남았어요!")
      }
      /// 갖고 싶은 것들이
      /// %d개 남았어요!
      internal static func wantToGet(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.title_format.want_to_get", p1, fallback: "갖고 싶은 것들이\n%d개 남았어요!")
      }
      /// 가고 싶은 장소가
      /// %d개 남았어요!
      internal static func wantToGo(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.title_format.want_to_go", p1, fallback: "가고 싶은 장소가\n%d개 남았어요!")
      }
    }
    internal enum Toast {
      /// GH-64 홈
      internal static let addedToFinished = Strings.tr("Localization", "home.toast.added_to_finished", fallback: "👏 이룬 싶에 담았어요")
    }
    internal enum YearReview {
      /// %@년 돌아보기
      internal static func captionFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "home.year_review.caption_format", String(describing: p1), fallback: "%@년 돌아보기")
      }
      /// 올해 배너 닫기
      internal static let close = Strings.tr("Localization", "home.year_review.close", fallback: "올해 배너 닫기")
      /// %d개
      internal static func countFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.year_review.count_format", p1, fallback: "%d개")
      }
      /// 올해 싶 %d개를 이뤘어요!
      internal static func titleFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "home.year_review.title_format", p1, fallback: "올해 싶 %d개를 이뤘어요!")
      }
    }
  }
  internal enum License {
    /// 싶은 아래 오픈소스를 사용해요. 각 라이선스 전문은 저장소에서 볼 수 있어요.
    internal static let description = Strings.tr("Localization", "license.description", fallback: "싶은 아래 오픈소스를 사용해요. 각 라이선스 전문은 저장소에서 볼 수 있어요.")
    /// 오픈소스 라이선스
    internal static let title = Strings.tr("Localization", "license.title", fallback: "오픈소스 라이선스")
  }
  internal enum MainTab {
    /// 이룬 싶
    internal static let finished = Strings.tr("Localization", "main_tab.finished", fallback: "이룬 싶")
    /// 새로 이룬 싶이 있어요
    internal static let finishedDotAccessibility = Strings.tr("Localization", "main_tab.finished_dot_accessibility", fallback: "새로 이룬 싶이 있어요")
    /// 설정
    internal static let settings = Strings.tr("Localization", "main_tab.settings", fallback: "설정")
    /// GH-64 메인 탭 · 적기 시트
    internal static let wish = Strings.tr("Localization", "main_tab.wish", fallback: "싶")
    /// 적기
    internal static let write = Strings.tr("Localization", "main_tab.write", fallback: "적기")
  }
  internal enum NotificationEditor {
    /// 알림 삭제
    internal static let delete = Strings.tr("Localization", "notification_editor.delete", fallback: "알림 삭제")
    /// 🔕 이미 설정된 알림입니다.
    internal static let duplicate = Strings.tr("Localization", "notification_editor.duplicate", fallback: "🔕 이미 설정된 알림입니다.")
  }
  internal enum PlaceMap {
    /// 장소를 붙인 곳 %d곳
    internal static func countFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "place_map.count_format", p1, fallback: "장소를 붙인 곳 %d곳")
    }
    /// 아직 장소를 붙인 곳이 없어요.
    internal static let empty = Strings.tr("Localization", "place_map.empty", fallback: "아직 장소를 붙인 곳이 없어요.")
    /// 가고 싶은 곳 지도
    internal static let title = Strings.tr("Localization", "place_map.title", fallback: "가고 싶은 곳 지도")
  }
  internal enum Settings {
    /// 문의하기
    internal static let contact = Strings.tr("Localization", "settings.contact", fallback: "문의하기")
    /// 제어 센터 · 단축어로 적기
    internal static let controlGuide = Strings.tr("Localization", "settings.control_guide", fallback: "제어 센터 · 단축어로 적기")
    /// 싶은 서버 없이 이 기기에만 저장돼요. 앱을 지우면 적어 둔 싶도 함께 지워져요.
    internal static let footer = Strings.tr("Localization", "settings.footer", fallback: "싶은 서버 없이 이 기기에만 저장돼요. 앱을 지우면 적어 둔 싶도 함께 지워져요.")
    /// 오픈소스 라이선스
    internal static let license = Strings.tr("Localization", "settings.license", fallback: "오픈소스 라이선스")
    /// 앱 평가하기
    internal static let rateApp = Strings.tr("Localization", "settings.rate_app", fallback: "앱 평가하기")
    /// 설정
    internal static let title = Strings.tr("Localization", "settings.title", fallback: "설정")
    /// 버전
    internal static let version = Strings.tr("Localization", "settings.version", fallback: "버전")
    /// 위젯 추가하는 법
    internal static let widgetGuide = Strings.tr("Localization", "settings.widget_guide", fallback: "위젯 추가하는 법")
    internal enum Contact {
      /// 
      /// 
      /// 
      /// ---
      /// 앱 버전: %@
      /// iOS 버전: %@
      /// 기기: %@
      internal static func bodyFormat(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
        return Strings.tr("Localization", "settings.contact.body_format", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "\n\n\n---\n앱 버전: %@\niOS 버전: %@\n기기: %@")
      }
      /// 메일 앱을 열 수 없어 주소를 복사했어요. %@ 로 보내주세요
      internal static func copiedFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "settings.contact.copied_format", String(describing: p1), fallback: "메일 앱을 열 수 없어 주소를 복사했어요. %@ 로 보내주세요")
      }
      /// [싶 문의]
      internal static let subject = Strings.tr("Localization", "settings.contact.subject", fallback: "[싶 문의]")
    }
    internal enum Group {
      /// 정보
      internal static let info = Strings.tr("Localization", "settings.group.info", fallback: "정보")
      /// 잠금과 알림
      internal static let lockNotification = Strings.tr("Localization", "settings.group.lock_notification", fallback: "잠금과 알림")
      /// 바로 적기
      internal static let quickWrite = Strings.tr("Localization", "settings.group.quick_write", fallback: "바로 적기")
      /// 보기
      internal static let view = Strings.tr("Localization", "settings.group.view", fallback: "보기")
    }
    internal enum Lock {
      /// 앱을 열 때 %@나 기기 암호로 확인해요
      internal static func descriptionFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "settings.lock.description_format", String(describing: p1), fallback: "앱을 열 때 %@나 기기 암호로 확인해요")
      }
      /// 앱을 열 때 기기 암호로 확인해요
      internal static let descriptionPasscode = Strings.tr("Localization", "settings.lock.description_passcode", fallback: "앱을 열 때 기기 암호로 확인해요")
      /// %@로 잠그기
      internal static func titleFormat(_ p1: Any) -> String {
        return Strings.tr("Localization", "settings.lock.title_format", String(describing: p1), fallback: "%@로 잠그기")
      }
      /// 암호로 잠그기
      internal static let titlePasscode = Strings.tr("Localization", "settings.lock.title_passcode", fallback: "암호로 잠그기")
    }
    internal enum Notification {
      /// 아이폰 설정에서 바꿀 수 있어요
      internal static let description = Strings.tr("Localization", "settings.notification.description", fallback: "아이폰 설정에서 바꿀 수 있어요")
      /// 꺼짐
      internal static let off = Strings.tr("Localization", "settings.notification.off", fallback: "꺼짐")
      /// 켜짐
      internal static let on = Strings.tr("Localization", "settings.notification.on", fallback: "켜짐")
      /// D-day 알림
      internal static let title = Strings.tr("Localization", "settings.notification.title", fallback: "D-day 알림")
    }
    internal enum StartCategory {
      /// 앱을 열면 처음 보일 탭이에요
      internal static let description = Strings.tr("Localization", "settings.start_category.description", fallback: "앱을 열면 처음 보일 탭이에요")
      /// 마지막으로 본 카테고리
      internal static let last = Strings.tr("Localization", "settings.start_category.last", fallback: "마지막으로 본 카테고리")
      /// 마지막으로 본
      internal static let lastShort = Strings.tr("Localization", "settings.start_category.last_short", fallback: "마지막으로 본")
      /// 시작 카테고리
      internal static let title = Strings.tr("Localization", "settings.start_category.title", fallback: "시작 카테고리")
    }
    internal enum ViewType {
      /// 취소
      internal static let cancel = Strings.tr("Localization", "settings.view_type.cancel", fallback: "취소")
      /// 그리드
      internal static let grid = Strings.tr("Localization", "settings.view_type.grid", fallback: "그리드")
      /// 리스트
      internal static let list = Strings.tr("Localization", "settings.view_type.list", fallback: "리스트")
      /// 홈 보기 방식
      internal static let title = Strings.tr("Localization", "settings.view_type.title", fallback: "홈 보기 방식")
    }
  }
  internal enum SharePhoto {
    /// 취소
    internal static let alertCancel = Strings.tr("Localization", "share_photo.alert_cancel", fallback: "취소")
    /// 설정
    internal static let alertSettings = Strings.tr("Localization", "share_photo.alert_settings", fallback: "설정")
    /// 공유할 카드. 두 번 탭하면 글자색이 바뀌어요
    internal static let cardAccessibility = Strings.tr("Localization", "share_photo.card_accessibility", fallback: "공유할 카드. 두 번 탭하면 글자색이 바뀌어요")
    /// 이미지를 저장하지 못했어요. 다시 시도해 주세요.
    internal static let saveFailed = Strings.tr("Localization", "share_photo.save_failed", fallback: "이미지를 저장하지 못했어요. 다시 시도해 주세요.")
    /// GH-64 사진 공유
    internal static let savedToast = Strings.tr("Localization", "share_photo.saved_toast", fallback: "👏이미지를 앨범에 저장했어요!")
  }
  internal enum WidgetGuide {
    /// 위젯 추가하는 법
    internal static let title = Strings.tr("Localization", "widget_guide.title", fallback: "위젯 추가하는 법")
    internal enum Home {
      /// 바로 적기 · 남은 싶 · 바로 체크하기 위젯을 홈 화면에 둘 수 있어요.
      internal static let description = Strings.tr("Localization", "widget_guide.home.description", fallback: "바로 적기 · 남은 싶 · 바로 체크하기 위젯을 홈 화면에 둘 수 있어요.")
      /// 홈 화면의 빈 곳을 길게 눌러요.
      internal static let step1 = Strings.tr("Localization", "widget_guide.home.step1", fallback: "홈 화면의 빈 곳을 길게 눌러요.")
      /// 왼쪽 위 편집 → 위젯 추가를 누르고 "싶"을 찾아요.
      internal static let step2 = Strings.tr("Localization", "widget_guide.home.step2", fallback: "왼쪽 위 편집 → 위젯 추가를 누르고 \"싶\"을 찾아요.")
      /// 원하는 크기를 골라 위젯 추가를 눌러요.
      internal static let step3 = Strings.tr("Localization", "widget_guide.home.step3", fallback: "원하는 크기를 골라 위젯 추가를 눌러요.")
      /// 홈 화면 위젯
      internal static let title = Strings.tr("Localization", "widget_guide.home.title", fallback: "홈 화면 위젯")
    }
    internal enum Lock {
      /// 다가오는 D-day와 남은 싶을 잠금화면에서 바로 볼 수 있어요.
      internal static let description = Strings.tr("Localization", "widget_guide.lock.description", fallback: "다가오는 D-day와 남은 싶을 잠금화면에서 바로 볼 수 있어요.")
      /// 잠금화면을 길게 누르고 사용자화를 눌러요.
      internal static let step1 = Strings.tr("Localization", "widget_guide.lock.step1", fallback: "잠금화면을 길게 누르고 사용자화를 눌러요.")
      /// 잠금화면을 고르고 시계 아래 위젯 자리를 눌러요.
      internal static let step2 = Strings.tr("Localization", "widget_guide.lock.step2", fallback: "잠금화면을 고르고 시계 아래 위젯 자리를 눌러요.")
      /// "싶"에서 원하는 위젯을 골라요.
      internal static let step3 = Strings.tr("Localization", "widget_guide.lock.step3", fallback: "\"싶\"에서 원하는 위젯을 골라요.")
      /// 잠금화면 위젯
      internal static let title = Strings.tr("Localization", "widget_guide.lock.title", fallback: "잠금화면 위젯")
    }
  }
  internal enum WishDocument {
    /// 취소
    internal static let cancel = Strings.tr("Localization", "wish_document.cancel", fallback: "취소")
    /// 카테고리 바꾸기
    internal static let categoryMenu = Strings.tr("Localization", "wish_document.category_menu", fallback: "카테고리 바꾸기")
    /// 날짜 없애기
    internal static let dateRemove = Strings.tr("Localization", "wish_document.date_remove", fallback: "날짜 없애기")
    /// 완료
    internal static let done = Strings.tr("Localization", "wish_document.done", fallback: "완료")
    /// ＃태그
    internal static let hashtagEmpty = Strings.tr("Localization", "wish_document.hashtag_empty", fallback: "＃태그")
    /// https://
    internal static let linkPlaceholder = Strings.tr("Localization", "wish_document.link_placeholder", fallback: "https://")
    /// 필요한 정보가 또 있나요?
    internal static let memoPlaceholder = Strings.tr("Localization", "wish_document.memo_placeholder", fallback: "필요한 정보가 또 있나요?")
    /// 길게 누르면 무작위로 골라요
    internal static let randomTooltip = Strings.tr("Localization", "wish_document.random_tooltip", fallback: "길게 누르면 무작위로 골라요")
    /// 지우기
    internal static let remove = Strings.tr("Localization", "wish_document.remove", fallback: "지우기")
    /// 저장
    internal static let save = Strings.tr("Localization", "wish_document.save", fallback: "저장")
    /// ＋ 추가
    internal static let stepAdd = Strings.tr("Localization", "wish_document.step_add", fallback: "＋ 추가")
    internal enum Chip {
      /// 날짜
      internal static let date = Strings.tr("Localization", "wish_document.chip.date", fallback: "날짜")
      /// 미래의 나에게
      internal static let letter = Strings.tr("Localization", "wish_document.chip.letter", fallback: "미래의 나에게")
      /// 링크
      internal static let link = Strings.tr("Localization", "wish_document.chip.link", fallback: "링크")
      /// 메모
      internal static let memo = Strings.tr("Localization", "wish_document.chip.memo", fallback: "메모")
      /// 알림
      internal static let notification = Strings.tr("Localization", "wish_document.chip.notification", fallback: "알림")
      /// 사진
      internal static let photo = Strings.tr("Localization", "wish_document.chip.photo", fallback: "사진")
      /// 장소
      internal static let place = Strings.tr("Localization", "wish_document.chip.place", fallback: "장소")
      /// 단계
      internal static let steps = Strings.tr("Localization", "wish_document.chip.steps", fallback: "단계")
      /// 목표 금액
      internal static let targetAmount = Strings.tr("Localization", "wish_document.chip.target_amount", fallback: "목표 금액")
    }
    internal enum Discard {
      /// 적던 내용을 버릴까요?
      internal static let addTitle = Strings.tr("Localization", "wish_document.discard.add_title", fallback: "적던 내용을 버릴까요?")
      /// 버리기
      internal static let confirm = Strings.tr("Localization", "wish_document.discard.confirm", fallback: "버리기")
      /// 고친 내용을 버릴까요?
      internal static let editTitle = Strings.tr("Localization", "wish_document.discard.edit_title", fallback: "고친 내용을 버릴까요?")
      /// 계속 쓰기
      internal static let keep = Strings.tr("Localization", "wish_document.discard.keep", fallback: "계속 쓰기")
    }
    internal enum HashtagSheet {
      /// 태그
      internal static let title = Strings.tr("Localization", "wish_document.hashtag_sheet.title", fallback: "태그")
    }
    internal enum Section {
      /// 알림
      internal static let notification = Strings.tr("Localization", "wish_document.section.notification", fallback: "알림")
    }
  }
  internal enum WishForm {
    /// 닫기
    internal static let close = Strings.tr("Localization", "wish_form.close", fallback: "닫기")
    /// 확인
    internal static let dateConfirm = Strings.tr("Localization", "wish_form.date_confirm", fallback: "확인")
    /// 이모지 고르기
    internal static let emojiAccessibility = Strings.tr("Localization", "wish_form.emoji_accessibility", fallback: "이모지 고르기")
    /// GH-64 작성·수정
    internal static let keyboardDone = Strings.tr("Localization", "wish_form.keyboard_done", fallback: "완료")
    /// 알림 허용을 위해선 날짜 지정이 필요해요.
    internal static let notificationRequiresDate = Strings.tr("Localization", "wish_form.notification_requires_date", fallback: "알림 허용을 위해선 날짜 지정이 필요해요.")
    /// %@, %@
    internal static func notificationRowFormat(_ p1: Any, _ p2: Any) -> String {
      return Strings.tr("Localization", "wish_form.notification_row_format", String(describing: p1), String(describing: p2), fallback: "%@, %@")
    }
    /// 무작위 이모지
    internal static let randomEmojiAccessibility = Strings.tr("Localization", "wish_form.random_emoji_accessibility", fallback: "무작위 이모지")
  }
  internal enum WishSearch {
    /// 제목·메모·해시태그에서 찾아봤어요
    internal static let emptyDescription = Strings.tr("Localization", "wish_search.empty_description", fallback: "제목·메모·해시태그에서 찾아봤어요")
    /// ‘%@’ 위시는 아직 없네요.
    internal static func emptyTitleFormat(_ p1: Any) -> String {
      return Strings.tr("Localization", "wish_search.empty_title_format", String(describing: p1), fallback: "‘%@’ 위시는 아직 없네요.")
    }
    /// 메모 · %@
    internal static func memoFormat(_ p1: Any) -> String {
      return Strings.tr("Localization", "wish_search.memo_format", String(describing: p1), fallback: "메모 · %@")
    }
    /// 제목·메모·해시태그로 찾기
    internal static let placeholder = Strings.tr("Localization", "wish_search.placeholder", fallback: "제목·메모·해시태그로 찾기")
    /// 위시 %d개를 찾았어요
    internal static func resultCountFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "wish_search.result_count_format", p1, fallback: "위시 %d개를 찾았어요")
    }
    /// %d개
    internal static func resultCountHighlightFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "wish_search.result_count_highlight_format", p1, fallback: "%d개")
    }
    /// 검색
    internal static let title = Strings.tr("Localization", "wish_search.title", fallback: "검색")
  }
  internal enum Write {
    internal enum Link {
      /// http:// 또는 https:// 로 시작하는 링크를 넣어주세요
      internal static let errorInvalid = Strings.tr("Localization", "write.link.error_invalid", fallback: "http:// 또는 https:// 로 시작하는 링크를 넣어주세요")
      /// 미리보기를 불러오지 못했어요
      internal static let previewFailed = Strings.tr("Localization", "write.link.preview_failed", fallback: "미리보기를 불러오지 못했어요")
      /// 링크
      internal static let title = Strings.tr("Localization", "write.link.title", fallback: "링크")
    }
    internal enum Step {
      /// 단계 (선택)
      internal static let title = Strings.tr("Localization", "write.step.title", fallback: "단계 (선택)")
    }
    internal enum TargetAmount {
      /// 상세 화면에서 모은 돈을 기록할 수 있어요
      internal static let caption = Strings.tr("Localization", "write.target_amount.caption", fallback: "상세 화면에서 모은 돈을 기록할 수 있어요")
      /// 0
      internal static let placeholder = Strings.tr("Localization", "write.target_amount.placeholder", fallback: "0")
      /// 목표 금액
      internal static let title = Strings.tr("Localization", "write.target_amount.title", fallback: "목표 금액")
    }
  }
  internal enum WriteCategorySheet {
    /// 뭐 하고 싶어요?
    internal static let ctaWantToDo = Strings.tr("Localization", "write_category_sheet.cta_want_to_do", fallback: "뭐 하고 싶어요?")
    /// 뭐 갖고 싶어요?
    internal static let ctaWantToGet = Strings.tr("Localization", "write_category_sheet.cta_want_to_get", fallback: "뭐 갖고 싶어요?")
    /// 어디 가고 싶어요?
    internal static let ctaWantToGo = Strings.tr("Localization", "write_category_sheet.cta_want_to_go", fallback: "어디 가고 싶어요?")
    /// 어떤 싶을
    /// 적어볼까요?
    internal static let title = Strings.tr("Localization", "write_category_sheet.title", fallback: "어떤 싶을\n적어볼까요?")
    /// 적어볼까요?
    internal static let titleBold = Strings.tr("Localization", "write_category_sheet.title_bold", fallback: "적어볼까요?")
  }
  internal enum YearReview {
    /// 닫기
    internal static let close = Strings.tr("Localization", "year_review.close", fallback: "닫기")
    /// %d개
    internal static func countFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "year_review.count_format", p1, fallback: "%d개")
    }
    /// 싶 %d개를 이뤘어요!
    internal static func headlineBoldFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "year_review.headline_bold_format", p1, fallback: "싶 %d개를 이뤘어요!")
    }
    /// 올해 나는
    /// 싶 %d개를 이뤘어요!
    internal static func headlineFormat(_ p1: Int) -> String {
      return Strings.tr("Localization", "year_review.headline_format", p1, fallback: "올해 나는\n싶 %d개를 이뤘어요!")
    }
    /// 이미지로 공유하기
    internal static let share = Strings.tr("Localization", "year_review.share", fallback: "이미지로 공유하기")
    /// 올해 이룬 싶 모두 보기
    internal static let showAll = Strings.tr("Localization", "year_review.show_all", fallback: "올해 이룬 싶 모두 보기")
    internal enum BusiestMonth {
      /// %d월 · %d개
      internal static func format(_ p1: Int, _ p2: Int) -> String {
        return Strings.tr("Localization", "year_review.busiest_month.format", p1, p2, fallback: "%d월 · %d개")
      }
      /// 가장 많이 이룬 달
      internal static let title = Strings.tr("Localization", "year_review.busiest_month.title", fallback: "가장 많이 이룬 달")
    }
    internal enum List {
      /// %d개 모두 모아봤어요
      internal static func headlineBoldFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "year_review.list.headline_bold_format", p1, fallback: "%d개 모두 모아봤어요")
      }
      /// %@년에 이룬 싶
      /// %d개 모두 모아봤어요
      internal static func headlineFormat(_ p1: Any, _ p2: Int) -> String {
        return Strings.tr("Localization", "year_review.list.headline_format", String(describing: p1), p2, fallback: "%@년에 이룬 싶\n%d개 모두 모아봤어요")
      }
      /// %d월
      internal static func monthFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "year_review.list.month_format", p1, fallback: "%d월")
      }
    }
    internal enum LongestHeld {
      /// %d일
      internal static func daysBoldFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "year_review.longest_held.days_bold_format", p1, fallback: "%d일")
      }
      /// 적고 나서 %d일 만에 이뤘어요
      internal static func daysFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "year_review.longest_held.days_format", p1, fallback: "적고 나서 %d일 만에 이뤘어요")
      }
      /// 가장 오래 품고 이룬 싶
      internal static let title = Strings.tr("Localization", "year_review.longest_held.title", fallback: "가장 오래 품고 이룬 싶")
    }
    internal enum NoteOfYear {
      /// 올해의 한 줄
      internal static let title = Strings.tr("Localization", "year_review.note_of_year.title", fallback: "올해의 한 줄")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
