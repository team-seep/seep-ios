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

/// 폼에서 키보드로 입력하는 칸
enum WishFormField: Hashable {
    case title
    case targetAmount
    case link
    case memo
    case hashtag
}

/// 작성 화면 (GH-70 R-10). 빈 문서를 전체 화면으로 띄운다.
/// `onFinish`는 저장한 위시(닫기면 nil)를 넘기고, 화면 닫기는 띄운 쪽이 한다
struct WishFormScreen: View {
    let mode: WishFormMode
    let onFinish: (Wish?) -> Void

    @State private var viewModel: WishFormViewModel

    /// - Parameter previousWishId: "이어서 적기"로 열었으면 앞 위시 id (GH-84 R-2)
    init(mode: WishFormMode, previousWishId: String? = nil, onFinish: @escaping (Wish?) -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        _viewModel = State(initialValue: WishFormViewModel(config: .init(mode: mode, previousWishId: previousWishId)))
    }

    /// 테스트·프리뷰에서 ViewModel 을 넣는다
    init(mode: WishFormMode, viewModel: WishFormViewModel, onFinish: @escaping (Wish?) -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            WishDocumentEditor(viewModel: viewModel, onFinish: onFinish)
        }
    }
}
