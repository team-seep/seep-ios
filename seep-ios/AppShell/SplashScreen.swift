import SwiftUI

import Lottie

/// 지금 스플래시(초록 바탕 + Lottie 3종 중 하나)를 SwiftUI 로 옮긴 것. 디자인 개편은 #63(GH-64 P3)
struct SplashScreen: View {
    let onFinish: () -> Void

    @State private var animationName = "splash\(Int.random(in: 1..<4))"

    var body: some View {
        ZStack {
            Color.tennisGreen.ignoresSafeArea()
            LottieView(animation: .named(animationName))
                .playing(loopMode: .playOnce)
                .animationDidFinish { _ in onFinish() }
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
                .accessibilityHidden(true)
        }
    }
}
