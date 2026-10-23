import Foundation

/// 위시 상세 문서의 본문 섹션 (GH-59 R-10). case 순서가 화면 순서다.
enum DetailSection: CaseIterable, Equatable {
    case memo
    case steps
    case savings
    case link
    case place
    case photo
    /// "미래의 나에게" 편지 — 문서 맨 아래 (GH-61 R-2)
    case letter
}

/// 위시 → 보일 섹션 목록 (GH-59 R-10, R-12). 노출 조건은 섹션별 ViewModel 과 같다:
/// 단계 `WishStepsViewModel`(상세는 0개면 숨김) · 모은 돈 `WishSavingsViewModel` · 링크 `WishLinkViewModel(.detail)` · 장소 `WishPlaceViewModel`.
enum DetailSectionBuilder {
    static func sections(for wish: Wish) -> [DetailSection] {
        return DetailSection.allCases.filter { isVisible($0, wish: wish) }
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
        case .photo:
            return true
        case .letter:
            // 이룬 위시는 편지가 있을 때만 (열린 편지). 이루기 전에는 늘 보인다 (GH-61 R-2, R-6)
            return !wish.isSuccess || wish.hasFutureLetter
        }
    }
}
