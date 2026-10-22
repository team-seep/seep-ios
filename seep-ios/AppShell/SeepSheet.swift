import SwiftUI

/// 시트 높이 규칙 (GH-64 A-5)
enum SeepSheetDetent: Equatable {
    /// 내용 높이에 맞춘다(PanModal 의 shortForm 처럼)
    case fitContent
    case medium
    case large
    case mediumLarge

    /// 인디케이터가 차지하는 위쪽 영역
    static let indicatorArea: CGFloat = 20

    /// 내용 높이로 detent 높이를 정한다. 소수점은 올려 내용이 잘리지 않게 한다 (TC-48)
    static func fitHeight(contentHeight: CGFloat) -> CGFloat {
        (contentHeight + indicatorArea).rounded(.up)
    }
}

extension View {
    /// 앱의 모든 시트는 이 modifier 로만 띄운다 (R5, 린트 `no_raw_sheet`).
    /// 잠금 오버레이·인디케이터·높이 규칙을 붙이고, 떠 있는 동안 `AppRouter`에 알려 위젯 링크를 막는다
    func seepSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        detent: SeepSheetDetent = .fitContent,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item, onDismiss: onDismiss) { item in
            content(item).modifier(SeepSheetContentModifier(detent: detent))
        }
    }

    func seepSheet<Content: View>(
        isPresented: Binding<Bool>,
        detent: SeepSheetDetent = .fitContent,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content().modifier(SeepSheetContentModifier(detent: detent))
        }
    }

    func seepFullScreenCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss) { item in
            content(item).modifier(SeepModalTrackingModifier()).appLockOverlay()
        }
    }
}

private struct SeepSheetContentModifier: ViewModifier {
    let detent: SeepSheetDetent
    @State private var contentHeight: CGFloat = 0
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                contentHeight = height
            }
            .presentationDetents(presentationDetents)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
            .modifier(SeepModalTrackingModifier())
            // 루트 토스트는 시트 뒤에 가려지므로 시트 안에도 같은 토스트를 그린다
            .modifier(OptionalToastOverlay(center: toastCenter))
            .appLockOverlay()
    }

    private var presentationDetents: Set<PresentationDetent> {
        switch detent {
        case .fitContent:
            // 처음 그릴 때는 높이를 모르니 medium 으로 시작했다가 측정한 높이로 바꾼다
            return contentHeight > 0 ? [.height(SeepSheetDetent.fitHeight(contentHeight: contentHeight))] : [.medium]
        case .medium:
            return [.medium]
        case .large:
            return [.large]
        case .mediumLarge:
            return [.medium, .large]
        }
    }
}

/// 시트가 떠 있는 동안 `AppRouter.presentedModalCount`를 올려 둔다(GH-50 링크 무시 규칙)
private struct SeepModalTrackingModifier: ViewModifier {
    @Environment(AppRouter.self) private var router: AppRouter?
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .onAppear { router?.modalDidAppear() }
            .onDisappear { router?.modalDidDisappear() }
            // 단축어로 작성 화면을 맨 위에 띄울 때 떠 있는 시트를 모두 닫는다 (GH-49 R-12)
            .onChange(of: router?.dismissAllModalsToken) { _, _ in
                dismiss()
            }
    }
}

private struct OptionalToastOverlay: ViewModifier {
    let center: ToastCenter?

    func body(content: Content) -> some View {
        if let center {
            content.toastOverlay(center)
        } else {
            content
        }
    }
}
