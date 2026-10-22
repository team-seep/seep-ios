import SwiftUI

/// 잠금 켜기·끄기 시트 (GH-46 디자인 After 1 / After 3).
/// 헤드라인 + gray4 설명 두 줄 + CTA + gray4 텍스트 버튼. 켜기 CTA 는 tennis-green, 끄기는 gray2 바탕 + gray5 글자
struct AppLockSheet: View {
    @State var viewModel: AppLockSheetViewModel
    let onDismiss: (Bool?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toastCenter

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(text: viewModel.state.title, boldPart: viewModel.state.titleBold)
                .padding(.top, 22)
                .padding(.horizontal, 2)
            Text(verbatim: viewModel.state.description)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.horizontal, 2)

            confirmButton
                .padding(.top, 28)

            Button {
                viewModel.send(.tapClose)
            } label: {
                Text(verbatim: viewModel.state.closeButtonTitle)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .trackScreen(viewModel.screenName)
        .onChange(of: viewModel.route) { _, route in
            handle(route)
        }
    }

    @ViewBuilder
    private var confirmButton: some View {
        if viewModel.state.isEnabled {
            // 끄기는 되돌리는 동작이라 강조색을 쓰지 않는다 (GH-46 디자인 After 3)
            Button {
                viewModel.send(.tapConfirm)
            } label: {
                Text(verbatim: viewModel.state.confirmButtonTitle)
                    .font(.appleExtraBold(size: 17))
                    .foregroundStyle(Color.gray5)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.gray2, in: Capsule())
            }
            .buttonStyle(.plain)
        } else {
            SeepCTA(title: viewModel.state.confirmButtonTitle, fillsWidth: true) {
                viewModel.send(.tapConfirm)
            }
        }
    }

    // MARK: Route

    private func handle(_ route: AppLockSheetViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .dismiss(let changedTo):
            onDismiss(changedTo)
            dismiss()
        case .toast(let message):
            toastCenter.show(message)
        }
        viewModel.send(.routeHandled)
    }
}
