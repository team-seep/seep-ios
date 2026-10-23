import SwiftUI

/// 흰 바탕 가운데 로고 + 한 줄 문구 (#63 R-1, R-2).
/// 로고는 LaunchScreen 과 같은 자리·크기(화면 가운데, 32×40)라 넘어갈 때 움직이지 않는다. 문구만 0.2초 페이드 인
struct SplashScreen: View {
    static let logoSize = CGSize(width: 32, height: 40)

    let onFinish: () -> Void

    @State private var viewModel = SplashViewModel()
    @State private var isTaglineVisible = false

    var body: some View {
        ZStack {
            Color.gray1.ignoresSafeArea()
            Assets.Icons.icLogoBlack.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: Self.logoSize.width, height: Self.logoSize.height)
                .overlay(alignment: .top) {
                    Text(Strings.splashTagline)
                        .font(.appleMedium(size: 14))
                        .foregroundStyle(Color.gray4)
                        .fixedSize()
                        .offset(y: Self.logoSize.height + 14)
                        .opacity(isTaglineVisible ? 1 : 0)
                }
                .accessibilityElement(children: .combine)
        }
        .ignoresSafeArea()
        .trackScreen(viewModel.screenName)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) {
                isTaglineVisible = true
            }
            viewModel.send(.onAppear)
        }
        .onChange(of: viewModel.route) { _, route in
            guard route == .goToMain else { return }
            viewModel.send(.routeHandled)
            onFinish()
        }
    }
}
