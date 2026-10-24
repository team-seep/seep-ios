import SwiftUI

/// 흰(다크는 어두운) 바탕 가운데 로고 + 한 줄 문구 (#63 R-1, R-2).
/// 로고는 LaunchScreen 과 같은 자리·크기(화면 가운데, 44×54)라 넘어갈 때 움직이지 않는다. 문구만 0.2초 페이드 인.
/// 로고가 벡터(SVG)라 키워도 흐리지 않다 (GH-74 R-3)
struct SplashScreen: View {
    static let logoSize = CGSize(width: 44, height: 54)

    let onFinish: () -> Void

    @State private var viewModel = SplashViewModel()
    @State private var isTaglineVisible = false

    var body: some View {
        ZStack {
            Color.gray1.ignoresSafeArea()
            // 다크에서도 보이게 글자색으로 칠한다 (GH-85 R-4). LaunchScreen 은 같은 모양의 템플릿 `ic_logo_launch`
            Assets.Icons.icLogoBlack.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Self.logoSize.width, height: Self.logoSize.height)
                .foregroundStyle(Color.gray5)
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
