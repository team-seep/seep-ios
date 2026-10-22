import SwiftUI

/// 작성·수정 폼을 여는 방식 (GH-64 P2)
enum WishFormMode: Identifiable, Equatable {
    case add(Category)
    case edit(Wish)

    var id: String {
        switch self {
        case .add(let category): return "add-" + category.rawValue
        case .edit(let wish): return "edit-" + wish.id
        }
    }

    static func == (lhs: WishFormMode, rhs: WishFormMode) -> Bool {
        lhs.id == rhs.id
    }
}

/// 위시 작성·수정 화면 (TC-401~409, 501~504).
/// GH-64 P2 병렬 작업용 자리. WRITE 담당이 채운다(이 이니셜라이저 모양은 유지).
/// `onFinish`는 저장한 위시(취소면 nil)를 넘기고, 화면 닫기는 띄운 쪽이 한다
struct WishFormScreen: View {
    let mode: WishFormMode
    let onFinish: (Wish?) -> Void

    var body: some View {
        PendingScreen(title: "WishFormScreen")
    }
}
