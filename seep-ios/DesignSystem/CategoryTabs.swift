import SwiftUI

/// 카테고리 알약 탭. 선택 = seep-blue 바탕 + 흰 ExtraBold 14 + 그림자, 비선택 = gray4 Medium 14 (디자인 시스템 CategoryTabs).
/// 넓은 화면에서도 간격이 벌어지지 않게 왼쪽 정렬로 붙인다 (GH-11)
struct CategoryTabs: View {
    let titles: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                Button {
                    selectedIndex = index
                } label: {
                    Text(verbatim: title)
                        .font(index == selectedIndex ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                        .foregroundStyle(index == selectedIndex ? Color.gray1 : Color.gray4)
                        .padding(.horizontal, 18)
                        .frame(height: 30)
                        .background {
                            if index == selectedIndex {
                                Capsule()
                                    .fill(Color.seepBlue)
                                    .shadow(color: .black.opacity(0.15), radius: 1.5, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
        .sensoryFeedback(.impact(weight: .light), trigger: selectedIndex)
    }
}
