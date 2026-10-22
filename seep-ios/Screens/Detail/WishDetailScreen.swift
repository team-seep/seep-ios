import SwiftUI

/// 위시 상세 — 읽는 문서(#59 D2) (TC-601~609).
/// GH-64 P2 병렬 작업용 자리. DETAIL 담당이 채운다(이 이니셜라이저 모양은 유지)
struct WishDetailScreen: View {
    let wishId: String
    /// 이룬 싶 탭(완료 목록)에서 열었는지 — 수정 버튼·메뉴 항목이 달라진다
    let isFinished: Bool

    var body: some View {
        PendingScreen(title: "WishDetailScreen")
    }
}
