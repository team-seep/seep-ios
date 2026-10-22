import SwiftUI

/// 연말 회고 전체 보기 (TC-903)
/// GH-64 P1 병렬 작업용 자리. 담당이 화면을 옮기면서 이 파일을 채운다(이 이니셜라이저 모양은 유지).
struct YearReviewListScreen: View {
    let year: Int

    var body: some View {
        PendingScreen(title: "YearReviewListScreen")
    }
}
