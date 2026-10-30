import SwiftUI

/// 작성 화면. 아이폰 탭 화면과 아이패드 사이드바 화면이 같이 쓴다.
/// 아이패드에서는 뒤의 목록이 보이는 가운데 큰 시트로 띄운다 (GH-64 R-9, GH-99 R-8)
struct WriteScreenPresenter: ViewModifier {
    @Environment(AppRouter.self) private var router

    func body(content: Content) -> some View {
        @Bindable var router = router

        content
            .seepFullScreenCover(item: $router.writeCategory, style: .pageSheetOnRegular) { category in
                WishFormScreen(mode: .add(category), previousWishId: router.writePreviousWishId) { savedWish in
                    router.writeCategory = nil
                    if let savedWish {
                        // 작성을 마치면 그 카테고리를 보여준다 (R-9)
                        router.showSavedWish(category: savedWish.category)
                    }
                }
            }
    }
}

/// 화면 폭으로 아이폰 탭 화면과 아이패드 사이드바 화면을 고른다. 기기 종류가 아니라 size class 로만 나눈다 (GH-99 R-2).
/// 아이패드에서도 화면 분할로 좁아지면(compact) 아이폰 화면이 쓰인다
struct MainLayoutView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// 레이아웃을 정한 뒤 부른다. 맡아 둔 위젯 링크를 그 레이아웃으로 연다 (R-13)
    var onAppear: () -> Void = {}

    var body: some View {
        Group {
            if router.isRegularLayout {
                PadRootView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            router.setRegularLayout(sizeClass == .regular)
            onAppear()
        }
        .onChange(of: sizeClass) { _, sizeClass in
            router.setRegularLayout(sizeClass == .regular)
        }
    }
}
