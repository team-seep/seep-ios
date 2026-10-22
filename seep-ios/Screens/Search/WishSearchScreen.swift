import SwiftUI

/// 검색 (GH-32, TC-701~)
/// GH-64 P1 병렬 작업용 자리. 담당이 화면을 옮기면서 이 파일을 채운다(이 이니셜라이저 모양은 유지).
struct WishSearchScreen: View {
    let finishedOnly: Bool

    var body: some View {
        PendingScreen(title: "WishSearchScreen")
    }
}
