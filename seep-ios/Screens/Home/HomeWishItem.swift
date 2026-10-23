import Foundation

/// 홈 리스트·그리드 한 칸이 그리는 값 (기존 `HomeWishCellViewModel` 출력)
struct HomeWishItem: Equatable, Identifiable {
    let wish: Wish
    /// 단계가 없으면 nil — 셀에서 진행도를 숨긴다 (GH-5)
    let stepProgress: WishStepProgress?
    /// 완료됐고 소감이 있을 때만 값이 있다 (GH-25 R-5)
    let finishNote: String?
    /// 셀에 핀 아이콘을 보여줄지 (GH-33 R-7)
    let isPinned: Bool
    /// 완료된 위시는 고정 메뉴를 띄우지 않는다 (GH-33 R-2)
    let canShowPinMenu: Bool
    /// 사진 파일이 실제로 있을 때만 값이 있다 — 그리드 셀이 사진 레이아웃을 쓴다 (GH-36 R-6, R-7)
    let photoFileName: String?

    var id: String { wish.id }

    init(wish: Wish, photoStorage: WishPhotoStorage) {
        self.wish = wish
        self.stepProgress = WishStepProgress(steps: wish.steps)
        self.finishNote = (wish.isSuccess && !wish.finishNote.isEmpty) ? wish.finishNote : nil
        self.isPinned = wish.isPinned
        self.canShowPinMenu = !wish.isSuccess
        self.photoFileName = photoStorage.photoURL(fileName: wish.photoFileName) != nil ? wish.photoFileName : nil
    }

    /// 해시태그 뱃지 문구. 기본 해시태그면 설명 문구, 직접 입력이면 그대로
    var tagText: String? {
        guard !wish.hashtag.isEmpty else { return nil }
        return HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag
    }
}

/// 오래 손대지 않은 위시에 "아직 하고 싶어요?"를 묻는 카드 (GH-30 R-6)
struct SleepingWishCard: Equatable {
    let wish: Wish
    /// "{n}일째 그대로예요"
    let caption: String
    /// "아직 {하고/갖고/가고} 싶어요?"
    let question: String
    /// "여전히 {하고/갖고/가고} 싶어요"
    let keepTitle: String
    let releaseTitle: String = Strings.Home.SleepingWish.release

    init(wish: Wish, daysSinceTouched: Int) {
        self.wish = wish
        self.caption = Strings.Home.SleepingWish.captionFormat(daysSinceTouched)
        switch wish.category {
        case .wantToDo:
            question = Strings.Home.SleepingWish.Question.wantToDo
            keepTitle = Strings.Home.SleepingWish.Keep.wantToDo
        case .wantToGet:
            question = Strings.Home.SleepingWish.Question.wantToGet
            keepTitle = Strings.Home.SleepingWish.Keep.wantToGet
        case .wantToGo:
            question = Strings.Home.SleepingWish.Question.wantToGo
            keepTitle = Strings.Home.SleepingWish.Keep.wantToGo
        }
    }
}

/// ViewModel 이 View 에 한 번 띄워 달라고 넘기는 토스트. 같은 문구가 연달아 와도 다시 띄우도록 id 를 둔다
struct HomeToast: Equatable {
    let id: Int
    let message: String
}
