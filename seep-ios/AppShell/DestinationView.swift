import SwiftUI

extension View {
    /// 탭 `NavigationStack`의 화면 목록. 탭 루트마다 붙인다
    func seepDestinations() -> some View {
        navigationDestination(for: AppDestination.self) { destination in
            DestinationView(destination: destination)
                .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

/// `AppDestination` → 화면. 화면을 SwiftUI 로 옮길 때마다 자기 case 만 바꾼다
struct DestinationView: View {
    let destination: AppDestination

    var body: some View {
        switch destination {
        case .wishDetail(let id, let isFinished):
            WishDetailScreen(wishId: id, isFinished: isFinished)
        case .search(let finishedOnly):
            WishSearchScreen(finishedOnly: finishedOnly)
        case .badgeCollection:
            BadgeCollectionScreen()
        case .yearReviewList(let year):
            YearReviewListScreen(year: year)
        case .placeMap:
            PlaceMapScreen()
        case .widgetGuide:
            WidgetGuideScreen()
        case .controlGuide:
            ControlGuideScreen()
        case .license:
            LicenseScreen()
        }
    }
}

/// 아직 SwiftUI 로 옮기지 않은 화면 자리. GH-64 단계 PR 사이에서만 보이고, P2가 끝나면 쓰는 곳이 없다
struct PendingScreen: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text(verbatim: title)
                .font(.appleBold(size: 17))
                .foregroundStyle(Color.gray5)
            Text(verbatim: "GH-64 · SwiftUI 전환 중")
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.gray3)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray2)
    }
}
