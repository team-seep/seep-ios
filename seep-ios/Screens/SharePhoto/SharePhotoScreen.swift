import SwiftUI

/// 사진 공유 (TC-1201~1203). 상세 ⋯ 메뉴 "공유하기"에서 `.seepFullScreenCover`로 띄운다.
/// GH-64 P2 병렬 작업용 자리. SHARE 담당이 채운다(이 이니셜라이저 모양은 유지)
struct SharePhotoScreen: View {
    let wish: Wish

    var body: some View {
        PendingScreen(title: "SharePhotoScreen")
    }
}
