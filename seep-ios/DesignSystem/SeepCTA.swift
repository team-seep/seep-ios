import SwiftUI

/// 실행 버튼(작성 CTA·시트 저장). 높이 50, 라운드 25, tennis-green, 흰 ExtraBold 17 (디자인 시스템 WriteButton).
/// 비활성은 cta-disabled 바탕
struct SeepCTA: View {
    let title: String
    var isEnabled: Bool = true
    var fillsWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.appleExtraBold(size: 17))
                .foregroundStyle(Color.onAccent)
                .padding(.horizontal, 30)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .frame(height: 50)
                .background(isEnabled ? Color.tennisGreen : Color.ctaDisabled, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
