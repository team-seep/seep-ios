import Foundation

/// 위시 상세 문서의 본문 섹션 (GH-59 R-10). case 순서가 화면 순서다.
enum DetailSection: CaseIterable, Equatable {
    case memo
    /// "이어지는 싶" — 메모 다음 (GH-84 R-4)
    case chain
    case steps
    /// 일지 — 단계와 모은 돈 사이 (GH-95 R-3)
    case journal
    case savings
    case link
    case place
    case photo
    /// "미래의 나에게" 편지 — 문서 맨 아래 (GH-61 R-2)
    case letter
}

/// 위시 → 보일 섹션 목록 (GH-59 R-10, R-12). 노출 조건은 섹션별 ViewModel 과 같다:
/// 단계 `WishStepsViewModel`(상세는 0개면 숨김) · 모은 돈 `WishSavingsViewModel` · 링크 `WishLinkViewModel(.detail)` · 장소 `WishPlaceViewModel`.
/// 사진·편지도 값이 있을 때만 보이고, 넣기·바꾸기는 작성/수정 문서에서 한다 (GH-61 R-9).
enum DetailSectionBuilder {
    /// - Parameters:
    ///   - hasPhoto: 사진 파일이 실제로 있는지. nil 이면 파일 이름으로 판단한다 (GH-36 R-7)
    ///   - isPhotoEditable: 수정 버튼이 없는 이룬 싶 탭 상세는 사진 빈 자리를 그대로 둔다 (GH-61 R-12)
    ///   - hasChain: 이어진 싶이 하나라도 있는지 (GH-84 R-4, R-6)
    ///   - isJournalEditable: 홈에서 연 상세는 일지가 없어도 "＋ 오늘 한 줄 남기기"를 보인다. 이룬 싶 상세는 일지가 있을 때만 (GH-95 R-3)
    static func sections(
        for wish: Wish,
        hasPhoto: Bool? = nil,
        isPhotoEditable: Bool = false,
        hasChain: Bool = false,
        isJournalEditable: Bool = false
    ) -> [DetailSection] {
        let hasPhoto = hasPhoto ?? !wish.photoFileName.isEmpty
        return DetailSection.allCases.filter { section in
            if section == .photo { return hasPhoto || isPhotoEditable }
            if section == .chain { return hasChain }
            if section == .journal { return isJournalEditable || !wish.journals.isEmpty }
            return isVisible(section, wish: wish)
        }
    }

    private static func isVisible(_ section: DetailSection, wish: Wish) -> Bool {
        switch section {
        case .memo:
            return wish.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .steps:
            return wish.steps.isEmpty == false
        case .savings:
            return wish.category == .wantToGet && wish.targetAmount > 0
        case .link:
            return wish.category == .wantToGet && WishLinkInput(text: wish.link).link != nil
        case .place:
            return wish.category == .wantToGo
        case .photo, .chain, .journal:
            return false
        case .letter:
            return wish.hasFutureLetter
        }
    }
}
