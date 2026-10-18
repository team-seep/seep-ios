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
  /// %02d개
  internal static func commonCategoryWantToDoUnit(_ p1: Int) -> String {
    return Strings.tr("Localization", "common_category_want_to_do_unit", p1, fallback: "%02d개")
  }
  /// 갖고 싶어요
  internal static let commonCategoryWantToGet = Strings.tr("Localization", "common_category_want_to_get", fallback: "갖고 싶어요")
  /// %02d개
  internal static func commonCategoryWantToGetUnit(_ p1: Int) -> String {
    return Strings.tr("Localization", "common_category_want_to_get_unit", p1, fallback: "%02d개")
  }
  /// 가고 싶어요
  internal static let commonCategoryWantToGo = Strings.tr("Localization", "common_category_want_to_go", fallback: "가고 싶어요")
  /// %02d곳
  internal static func commonCategoryWantToGoUnit(_ p1: Int) -> String {
    return Strings.tr("Localization", "common_category_want_to_go_unit", p1, fallback: "%02d곳")
  }
  /// 확인
  internal static let commonOk = Strings.tr("Localization", "common_ok", fallback: "확인")
  /// 취소하기
  internal static let detailActionSheetCancel = Strings.tr("Localization", "detail_action_sheet_cancel", fallback: "취소하기")
  /// 완료 취소하기
  internal static let detailActionSheetCancelFinish = Strings.tr("Localization", "detail_action_sheet_cancel_finish", fallback: "완료 취소하기")
  /// 삭제하기
  internal static let detailActionSheetDelete = Strings.tr("Localization", "detail_action_sheet_delete", fallback: "삭제하기")
  /// 수정하기
  internal static let detailActionSheetEdit = Strings.tr("Localization", "detail_action_sheet_edit", fallback: "수정하기")
  /// 공유하기
  internal static let detailActionSheetShare = Strings.tr("Localization", "detail_action_sheet_share", fallback: "공유하기")
  /// 😭 조금만...더!
  internal static let detailButtonMore = Strings.tr("Localization", "detail_button_more", fallback: "😭 조금만...더!")
  /// ✔️ 저장
  internal static let detailButtonOn = Strings.tr("Localization", "detail_button_on", fallback: "✔️ 저장")
  /// 취소
  internal static let detailCancel = Strings.tr("Localization", "detail_cancel", fallback: "취소")
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
  /// 메모 없음
  internal static let detailMemoEmpty = Strings.tr("Localization", "detail_memo_empty", fallback: "메모 없음")
  /// Random으로 이모지를
  /// 골라드립니다!
  internal static let detailRandomInfo = Strings.tr("Localization", "detail_random_info", fallback: "Random으로 이모지를\n골라드립니다!")
  /// 메인 홈으로 돌아가기
  internal static let finishBackButton = Strings.tr("Localization", "finish_back_button", fallback: "메인 홈으로 돌아가기")
  /// 지금까지
  /// %02d개 이뤘어요!
  internal static func finishCountCategoryWantToDoFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "finish_count_category_want_to_do_format", p1, fallback: "지금까지\n%02d개 이뤘어요!")
  }
  /// 지금까지
  /// %02d개 겟했어요!
  internal static func finishCountCategoryWantToGetFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "finish_count_category_want_to_get_format", p1, fallback: "지금까지\n%02d개 겟했어요!")
  }
  /// 지금까지
  /// %02d곳 다녀왔어요!
  internal static func finishCountCategoryWantToGoFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "finish_count_category_want_to_go_format", p1, fallback: "지금까지\n%02d곳 다녀왔어요!")
  }
  /// 하고 싶은게 많은 것만으로도
  /// 반짝반짝 빛나는 사람인걸요.
  /// 당신을 응원할게요!
  internal static let finishDescriptionEmpty = Strings.tr("Localization", "finish_description_empty", fallback: "하고 싶은게 많은 것만으로도\n반짝반짝 빛나는 사람인걸요.\n당신을 응원할게요!")
  /// 메인으로 돌아가기
  internal static let finishEmptyBackButton = Strings.tr("Localization", "finish_empty_back_button", fallback: "메인으로 돌아가기")
  /// 아직...
  /// 완료된 것이 없지만
  internal static let finishTitleEmpty = Strings.tr("Localization", "finish_title_empty", fallback: "아직...\n완료된 것이 없지만")
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
  /// 성공
  internal static let homeCategorySuccess = Strings.tr("Localization", "home_category_success", fallback: "성공")
  /// 👏 지금까지 %d개를 이뤘어요
  internal static func homeFinishCountCategoryWantToDoFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_finish_count_category_want_to_do_format", p1, fallback: "👏 지금까지 %d개를 이뤘어요")
  }
  /// 😱 지금까지 %d개를 이뤘어요
  internal static func homeFinishCountCategoryWantToDoFormatEmpty(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_finish_count_category_want_to_do_format_empty", p1, fallback: "😱 지금까지 %d개를 이뤘어요")
  }
  /// 👏 지금까지 %d개를 겟했어요
  internal static func homeFinishCountCategoryWantToGetFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_finish_count_category_want_to_get_format", p1, fallback: "👏 지금까지 %d개를 겟했어요")
  }
  /// 😱 지금까지 %d개를 겟했어요
  internal static func homeFinishCountCategoryWantToGetFormatEmpty(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_finish_count_category_want_to_get_format_empty", p1, fallback: "😱 지금까지 %d개를 겟했어요")
  }
  /// 👏 지금까지 %d곳을 다녀왔어요
  internal static func homeFinishCountCategoryWantToGoFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_finish_count_category_want_to_go_format", p1, fallback: "👏 지금까지 %d곳을 다녀왔어요")
  }
  /// 😱 지금까지 %d곳을 다녀왔어요
  internal static func homeFinishCountCategoryWantToGoFormatEmpty(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_finish_count_category_want_to_go_format_empty", p1, fallback: "😱 지금까지 %d곳을 다녀왔어요")
  }
  /// 먼훗날
  internal static let homeInFarFurture = Strings.tr("Localization", "home_in_far_furture", fallback: "먼훗날")
  /// 일정없음
  internal static let homeNoDeanline = Strings.tr("Localization", "home_no_deanline", fallback: "일정없음")
  /// 📝 뭐 하고 싶어요?
  internal static let homeWriteCategoryWantToDoButton = Strings.tr("Localization", "home_write_category_want_to_do_button", fallback: "📝 뭐 하고 싶어요?")
  /// 하고 싶은 것들을
  /// 적어봐요!
  internal static let homeWriteCategoryWantToDoCountEmpty = Strings.tr("Localization", "home_write_category_want_to_do_count_empty", fallback: "하고 싶은 것들을\n적어봐요!")
  /// 하고 싶은 것들이
  /// %02d개 남았어요!
  internal static func homeWriteCategoryWantToDoCountFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_write_category_want_to_do_count_format", p1, fallback: "하고 싶은 것들이\n%02d개 남았어요!")
  }
  /// 📝 뭐 갖고 싶어요?
  internal static let homeWriteCategoryWantToGetButton = Strings.tr("Localization", "home_write_category_want_to_get_button", fallback: "📝 뭐 갖고 싶어요?")
  /// 갖고 싶은 것들을
  /// 적어봐요!
  internal static let homeWriteCategoryWantToGetCountEmpty = Strings.tr("Localization", "home_write_category_want_to_get_count_empty", fallback: "갖고 싶은 것들을\n적어봐요!")
  /// 갖고 싶은 것들이
  /// %02d개 남았어요!
  internal static func homeWriteCategoryWantToGetCountFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_write_category_want_to_get_count_format", p1, fallback: "갖고 싶은 것들이\n%02d개 남았어요!")
  }
  /// 📝 어디 가고 싶어요?
  internal static let homeWriteCategoryWantToGoButton = Strings.tr("Localization", "home_write_category_want_to_go_button", fallback: "📝 어디 가고 싶어요?")
  /// 가고 싶은 곳들을
  /// 적어봐요!
  internal static let homeWriteCategoryWantToGoCountEmpty = Strings.tr("Localization", "home_write_category_want_to_go_count_empty", fallback: "가고 싶은 곳들을\n적어봐요!")
  /// 가고 싶은 곳들이
  /// %02d곳 남았어요!
  internal static func homeWriteCategoryWantToGoCountFormat(_ p1: Int) -> String {
    return Strings.tr("Localization", "home_write_category_want_to_go_count_format", p1, fallback: "가고 싶은 곳들이\n%02d곳 남았어요!")
  }
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
  /// 👌 공유하기 완료! 앨범에서 확인해보세요
  internal static let sharePhotoSuccess = Strings.tr("Localization", "share_photo_success", fallback: "👌 공유하기 완료! 앨범에서 확인해보세요")
  /// 공유하기
  internal static let sharePhotoTitle = Strings.tr("Localization", "share_photo_title", fallback: "공유하기")
  /// 👆화면을 두번 탭하면 텍스트 컬러를 바꿀 수 있어요
  internal static let sharePhotoTooltip = Strings.tr("Localization", "share_photo_tooltip", fallback: "👆화면을 두번 탭하면 텍스트 컬러를 바꿀 수 있어요")
  /// 알림 추가
  internal static let writeAddNotification = Strings.tr("Localization", "write_add_notification", fallback: "알림 추가")
  /// 😭 조금만...더!
  internal static let writeButtonMore = Strings.tr("Localization", "write_button_more", fallback: "😭 조금만...더!")
  /// 🔥어서 채워봅시다!
  internal static let writeButtonOff = Strings.tr("Localization", "write_button_off", fallback: "🔥어서 채워봅시다!")
  /// 🎉등록해볼까요!
  internal static let writeButtonOn = Strings.tr("Localization", "write_button_on", fallback: "🎉등록해볼까요!")
  /// 날짜 지정
  internal static let writeDateSwitchTitle = Strings.tr("Localization", "write_date_switch_title", fallback: "날짜 지정")
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
  /// 날짜
  internal static let writeHeaderDate = Strings.tr("Localization", "write_header_date", fallback: "날짜")
  /// 해시태그
  internal static let writeHeaderHashtag = Strings.tr("Localization", "write_header_hashtag", fallback: "해시태그")
  /// 메모
  internal static let writeHeaderMemo = Strings.tr("Localization", "write_header_memo", fallback: "메모")
  /// 알림
  internal static let writeHeaderNotification = Strings.tr("Localization", "write_header_notification", fallback: "알림")
  /// 제목
  internal static let writeHeaderTitle = Strings.tr("Localization", "write_header_title", fallback: "제목")
  /// 알림 허용
  internal static let writeNotificationSwitchTitle = Strings.tr("Localization", "write_notification_switch_title", fallback: "알림 허용")
  /// 지정된 날짜 없음
  internal static let writePlaceholderDateDisable = Strings.tr("Localization", "write_placeholder_date_disable", fallback: "지정된 날짜 없음")
  /// 언제까지 하면 좋을까요?
  internal static let writePlaceholderDateEnable = Strings.tr("Localization", "write_placeholder_date_enable", fallback: "언제까지 하면 좋을까요?")
  /// + 새로운 태그
  internal static let writePlaceholderHashtag = Strings.tr("Localization", "write_placeholder_hashtag", fallback: "+ 새로운 태그")
  /// 뭐 하고 싶어요?
  internal static let writePlaceholderTitleCategoryWantToDo = Strings.tr("Localization", "write_placeholder_title_category_want_to_do", fallback: "뭐 하고 싶어요?")
  /// 뭐 갖고 싶어요?
  internal static let writePlaceholderTitleCategoryWantToGet = Strings.tr("Localization", "write_placeholder_title_category_want_to_get", fallback: "뭐 갖고 싶어요?")
  /// 어디 가고 싶어요?
  internal static let writePlaceholderTitleCategoryWantToGo = Strings.tr("Localization", "write_placeholder_title_category_want_to_go", fallback: "어디 가고 싶어요?")
  /// R
  internal static let writeRandomButton = Strings.tr("Localization", "write_random_button", fallback: "R")
  /// 작은 것부터
  /// 차근차근 적어봐요!
  internal static let writeTitle = Strings.tr("Localization", "write_title", fallback: "작은 것부터\n차근차근 적어봐요!")
  /// 필요한 정보가 또 있나요? (선택)
  internal static let wrtiePlaceholderMemo = Strings.tr("Localization", "wrtie_placeholder_memo", fallback: "필요한 정보가 또 있나요? (선택)")
  /// 차근차근 적어봐요!
  internal static let wrtieTitleBold = Strings.tr("Localization", "wrtie_title_bold", fallback: "차근차근 적어봐요!")
  internal enum Common {
    /// %@원
    internal static func wonFormat(_ p1: Any) -> String {
      return Strings.tr("Localization", "common.won_format", String(describing: p1), fallback: "%@원")
    }
    /// 원
    internal static let wonUnit = Strings.tr("Localization", "common.won_unit", fallback: "원")
    internal enum WantToDo {
      /// %02d개
      internal static func unit(_ p1: Int) -> String {
        return Strings.tr("Localization", "common.want_to_do.unit", p1, fallback: "%02d개")
      }
    }
    internal enum WantToGet {
      /// %02d개
      internal static func unit(_ p1: Int) -> String {
        return Strings.tr("Localization", "common.want_to_get.unit", p1, fallback: "%02d개")
      }
    }
    internal enum WantToGo {
      /// %02d곳
      internal static func unit(_ p1: Int) -> String {
        return Strings.tr("Localization", "common.want_to_go.unit", p1, fallback: "%02d곳")
      }
    }
  }
  internal enum Detail {
    internal enum Saving {
      /// 모은 돈 기록
      internal static let add = Strings.tr("Localization", "detail.saving.add", fallback: "모은 돈 기록")
      /// 다 모았어요! 이제 겟할 시간이에요
      internal static let completed = Strings.tr("Localization", "detail.saving.completed", fallback: "다 모았어요! 이제 겟할 시간이에요")
      /// 기록 삭제
      internal static let delete = Strings.tr("Localization", "detail.saving.delete", fallback: "기록 삭제")
      /// %d%%
      internal static func percentFormat(_ p1: Int) -> String {
        return Strings.tr("Localization", "detail.saving.percent_format", p1, fallback: "%d%%")
      }
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
      /// 모으기
      internal static let title = Strings.tr("Localization", "detail.saving.title", fallback: "모으기")
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
    internal enum Step {
      /// 단계 추가
      internal static let add = Strings.tr("Localization", "detail.step.add", fallback: "단계 추가")
      /// 삭제
      internal static let delete = Strings.tr("Localization", "detail.step.delete", fallback: "삭제")
      /// %d/%d 완료
      internal static func progressFormat(_ p1: Int, _ p2: Int) -> String {
        return Strings.tr("Localization", "detail.step.progress_format", p1, p2, fallback: "%d/%d 완료")
      }
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
  internal enum Home {
    /// 아직 등록된 것이 없네요.
    /// 👇🏻아래 버튼을 누르면 작성할 수 있어요!
    internal static let empty = Strings.tr("Localization", "home.empty", fallback: "아직 등록된 것이 없네요.\n👇🏻아래 버튼을 누르면 작성할 수 있어요!")
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
    internal enum Filter {
      /// 완료된 위시만
      internal static let onlyFinished = Strings.tr("Localization", "home.filter.only_finished", fallback: "완료된 위시만")
      internal enum Sort {
        /// 완료일 가까운순
        internal static let deadline = Strings.tr("Localization", "home.filter.sort.deadline", fallback: "완료일 가까운순")
        /// 최근 생성순
        internal static let latest = Strings.tr("Localization", "home.filter.sort.latest", fallback: "최근 생성순")
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
      /// 👏위시를 완료했어요!
      internal static let finishWish = Strings.tr("Localization", "home.toast.finish_wish", fallback: "👏위시를 완료했어요!")
      /// 👏등록이 완료됐어요!
      internal static let successWrite = Strings.tr("Localization", "home.toast.success_write", fallback: "👏등록이 완료됐어요!")
    }
    internal enum WriteButton {
      /// 📝 뭐 하고 싶어요?
      internal static let wantToDo = Strings.tr("Localization", "home.write_button.want_to_do", fallback: "📝 뭐 하고 싶어요?")
      /// 📝 뭐 갖고 싶어요?
      internal static let wantToGet = Strings.tr("Localization", "home.write_button.want_to_get", fallback: "📝 뭐 갖고 싶어요?")
      /// 📝 어디 가고 싶어요?
      internal static let wantToGo = Strings.tr("Localization", "home.write_button.want_to_go", fallback: "📝 어디 가고 싶어요?")
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
  internal enum Write {
    internal enum Step {
      /// 단계 (선택)
      internal static let title = Strings.tr("Localization", "write.step.title", fallback: "단계 (선택)")
    }
    internal enum TargetAmount {
      /// 상세 화면에서 모은 돈을 기록할 수 있어요
      internal static let caption = Strings.tr("Localization", "write.target_amount.caption", fallback: "상세 화면에서 모은 돈을 기록할 수 있어요")
      ///  (선택)
      internal static let `optional` = Strings.tr("Localization", "write.target_amount.optional", fallback: " (선택)")
      /// 0
      internal static let placeholder = Strings.tr("Localization", "write.target_amount.placeholder", fallback: "0")
      /// 목표 금액
      internal static let title = Strings.tr("Localization", "write.target_amount.title", fallback: "목표 금액")
    }
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
      /// 뒤로
      internal static let back = Strings.tr("Localization", "year_review.list.back", fallback: "뒤로")
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
