import Foundation

/// 위시를 지운 뒤 위시 밖에 남는 것을 정리한다. 홈 삭제·잠든 위시 보내기와 상세 삭제(P2)가 같이 쓴다
struct WishDeletionCleanup {
    let preference: Preference
    let linkPreviewCache: LinkPreviewCaching
    let photoStorage: WishPhotoStorage

    func run(wish: Wish) {
        // 캘린더 이벤트는 쓰기 전용 권한이라 지울 수 없고, "추가됨" 기록만 지운다 (GH-28 R-8)
        preference.setCalendarEventId(nil, wishId: wish.id)
        // 링크 미리보기 캐시도 같이 지운다 (GH-29 R-5)
        linkPreviewCache.remove(wishId: wish.id)
        // 상세에서 방금 바꾼 사진까지 지우도록 위시 id 로 지운다 (GH-36 R-5)
        photoStorage.deletePhotos(wishId: wish.id)
    }
}
