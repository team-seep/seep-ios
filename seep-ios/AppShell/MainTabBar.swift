import SwiftUI

/// 탭 바. 흰 바탕·위 1pt gray2-5 선, 아이콘 26 + 라벨 11, 선택 seep-blue / 나머지 gray4.
/// 적기만 tennis-green 원(30) 안 흰 ＋, 라벨 gray5, 선택 상태가 없다 (R-2)
struct MainTabBar: View {
    let selectedTab: MainTab
    let showsFinishedDot: Bool
    let onTap: (MainTabItem) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabItem.allCases, id: \.self) { item in
                Button {
                    onTap(item)
                } label: {
                    label(for: item)
                        .frame(maxWidth: .infinity, minHeight: 49)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected(item) ? .isSelected : [])
            }
        }
        .background(Color.gray1.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray2_5)
                .frame(height: 1)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    @ViewBuilder
    private func label(for item: MainTabItem) -> some View {
        VStack(spacing: 2) {
            icon(for: item)
                .frame(width: 30, height: 30)
            Text(verbatim: title(for: item))
                .font(.appleBold(size: 11))
                .foregroundStyle(color(for: item))
        }
    }

    @ViewBuilder
    private func icon(for item: MainTabItem) -> some View {
        switch item {
        case .write:
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.gray1)
                .frame(width: 30, height: 30)
                .background(Color.tennisGreen, in: Circle())
        case .finished:
            Image(systemName: "checkmark.circle")
                .font(.system(size: 22))
                .foregroundStyle(color(for: item))
                .overlay(alignment: .topTrailing) {
                    if showsFinishedDot {
                        Circle()
                            .fill(Color.optionRed)
                            .frame(width: 7, height: 7)
                            .offset(x: 2, y: -1)
                            .accessibilityLabel(Text(Strings.MainTab.finishedDotAccessibility))
                    }
                }
        case .wish:
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 21))
                .foregroundStyle(color(for: item))
        case .settings:
            Image(systemName: "gearshape")
                .font(.system(size: 21))
                .foregroundStyle(color(for: item))
        }
    }

    private func title(for item: MainTabItem) -> String {
        switch item {
        case .wish: return Strings.MainTab.wish
        case .finished: return Strings.MainTab.finished
        case .write: return Strings.MainTab.write
        case .settings: return Strings.MainTab.settings
        }
    }

    private func isSelected(_ item: MainTabItem) -> Bool {
        switch item {
        case .wish: return selectedTab == .wish
        case .finished: return selectedTab == .finished
        case .settings: return selectedTab == .settings
        case .write: return false
        }
    }

    private func color(for item: MainTabItem) -> Color {
        if item == .write { return .gray5 }
        return isSelected(item) ? .seepBlue : .gray4
    }
}
