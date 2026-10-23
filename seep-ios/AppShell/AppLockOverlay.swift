import SwiftUI

extension View {
    /// 잠긴 동안 이 화면 위를 잠금 화면으로 덮는다 (GH-64 A-8).
    /// 루트와 모든 시트 내용 루트에 붙어야 시트 위까지 가려진다 — `seepSheet`가 자동으로 붙인다(R5).
    /// 환경에 `AppLockOverlayViewModel`이 없으면(프리뷰·테스트) 아무것도 하지 않는다
    func appLockOverlay() -> some View {
        modifier(AppLockOverlayModifier())
    }
}

private struct AppLockOverlayModifier: ViewModifier {
    @Environment(AppLockOverlayViewModel.self) private var viewModel: AppLockOverlayViewModel?

    func body(content: Content) -> some View {
        content.overlay {
            if let viewModel, viewModel.state.lockState != .unlocked {
                AppLockScreen(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
    }
}

/// 잠금 화면 / 앱 전환기 덮개. gray2 바탕 가운데 흰 원(72) 자물쇠 + 헤드라인 + 설명 + tennis-green 알약 버튼 (디자인 시스템, GH-46).
/// 덮개(covered)는 버튼 없이 가리기만 한다
struct AppLockScreen: View {
    let viewModel: AppLockOverlayViewModel

    var body: some View {
        ZStack {
            Color.gray2.ignoresSafeArea()
            VStack(spacing: 0) {
                Image(systemName: "lock")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.gray5)
                    .frame(width: 72, height: 72)
                    .background(Color.gray1, in: Circle())
                    .accessibilityHidden(true)
                titleText
                    .padding(.top, 24)
                Text(verbatim: viewModel.state.description)
                    .font(.appleRegular(size: 14))
                    .foregroundStyle(Color.gray4)
                    .padding(.top, 8)
            }
            if viewModel.state.lockState == .locked {
                VStack {
                    Spacer()
                    SeepCTA(title: viewModel.state.unlockButtonTitle) {
                        viewModel.send(.tapUnlock)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var titleText: Text {
        let title = Strings.AppLock.Screen.title
        let bold = Strings.AppLock.Screen.titleBold
        guard let range = title.range(of: bold) else {
            return Text(verbatim: title).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
        }
        let head = String(title[..<range.lowerBound])
        let tail = String(title[range.upperBound...])
        return Text(verbatim: head).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: bold).font(.appleBold(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: tail).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
    }
}
