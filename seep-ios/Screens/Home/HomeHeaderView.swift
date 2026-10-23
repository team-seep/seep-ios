import SwiftUI

/// 홈 헤드라인 두 줄 + 오른쪽 3D 일러스트 (디자인 시스템 Headline).
/// 남은 게 있으면 "{카테고리} 것들이 / **n개 남았어요!**"(개수 tennis-green), 없으면 "… / **적어봐요!**"
struct HomeOverviewView: View {
    let category: Category
    let count: Int?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            headline
                .padding(.top, 28)
                .padding(.leading, HomeHeaderLayout.headlineLeading)
            Spacer(minLength: 12)
            HomeIllustrationView(category: category)
                .padding(.top, 8)
                .padding(.trailing, HomeHeaderLayout.illustrationTrailingInset)
        }
        .frame(height: 140, alignment: .top)
    }

    private var headline: some View {
        headlineText
            .lineSpacing(9)
            .foregroundStyle(Color.gray5)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var headlineText: Text {
        guard let count, count > 0 else {
            return Self.styled(text: emptyTitle, bold: [Self.emptyBold], green: nil)
        }
        return Self.styled(text: countTitle(count), bold: [Self.countBold], green: unitText(count))
    }

    private var emptyTitle: String {
        switch category {
        case .wantToDo: return Strings.Home.EmptyTitle.wantToDo
        case .wantToGet: return Strings.Home.EmptyTitle.wantToGet
        case .wantToGo: return Strings.Home.EmptyTitle.wantToGo
        }
    }

    private func countTitle(_ count: Int) -> String {
        switch category {
        case .wantToDo: return Strings.Home.TitleFormat.wantToDo(count)
        case .wantToGet: return Strings.Home.TitleFormat.wantToGet(count)
        case .wantToGo: return Strings.Home.TitleFormat.wantToGo(count)
        }
    }

    /// 헤드라인 속 "n개" — 숫자부터 다음 공백 전까지. 단위 문자열(`%02d개`·`곳`)은 헤드라인(`%d개`)과 글자가 달라 쓰지 않는다
    private func unitText(_ count: Int) -> String {
        let text = countTitle(count)
        guard let start = text.range(of: "\(count)")?.lowerBound else { return "\(count)" }
        let end = text[start...].firstIndex(where: \.isWhitespace) ?? text.endIndex
        return String(text[start..<end])
    }

    private static let emptyBold = "적어봐요!"
    private static let countBold = "남았어요!"

    /// 문자열을 Light 22 로 그리고, 굵게 할 부분은 Bold 22, 개수는 Bold 22 tennis-green 으로 그린다
    private static func styled(text: String, bold: [String], green: String?) -> Text {
        var attributed = AttributedString(text)
        attributed.font = .appleLight(size: 22)
        for part in bold {
            if let range = attributed.range(of: part) {
                attributed[range].font = .appleBold(size: 22)
            }
        }
        if let green, let range = attributed.range(of: green) {
            attributed[range].font = .appleBold(size: 22)
            attributed[range].foregroundColor = .tennisGreen
        }
        return Text(attributed)
    }
}

/// 카테고리마다 바뀌는 3D 오브젝트 일러스트. 10도 기울여 위아래로 천천히 흔든다
struct HomeIllustrationView: View {
    let category: Category
    @State private var imageIndex = 1
    @State private var isSwaying = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        illustration
            .resizable()
            .scaledToFit()
            .frame(width: HomeHeaderLayout.illustrationSize, height: HomeHeaderLayout.illustrationSize)
            .rotationEffect(.degrees(HomeHeaderLayout.illustrationRotationDegrees + (isSwaying ? 10 : 0)))
            .offset(y: isSwaying ? 5 : 0)
            .accessibilityHidden(true)
            .onAppear {
                imageIndex = Self.randomIndex(for: category)
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.3)) {
                    isSwaying = true
                }
            }
            .onChange(of: category) { _, newCategory in
                imageIndex = Self.randomIndex(for: newCategory)
            }
    }

    private var illustration: Image {
        let prefix: String
        switch category {
        case .wantToDo: prefix = "img_category_do_"
        case .wantToGet: prefix = "img_category_get_"
        case .wantToGo: prefix = "img_category_go_"
        }
        return ImageAsset(name: prefix + "\(imageIndex)").swiftUIImage
    }

    private static func randomIndex(for category: Category) -> Int {
        switch category {
        case .wantToDo: return Int.random(in: 1...12)
        case .wantToGet, .wantToGo: return Int.random(in: 1...10)
        }
    }
}

/// 카테고리 탭. 선택 = seep-blue 알약 + 흰 ExtraBold 14, 비선택 = gray4 Medium 14.
/// 탭 줄은 최대 400pt 에 왼쪽 정렬하고 그 안에서 양끝 맞춤 (`HomeCategoryTabLayout`)
struct HomeCategoryTabs: View {
    let selected: Category
    let onSelect: (Category) -> Void

    private let categories: [Category] = [.wantToDo, .wantToGet, .wantToGo]

    var body: some View {
        HomeCategoryTabRowLayout {
            ForEach(categories) { category in
                let isSelected = category == selected
                Button {
                    onSelect(category)
                } label: {
                    Text(verbatim: category.title)
                        .font(isSelected ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                        .foregroundStyle(isSelected ? Color.gray1 : Color.gray4)
                        .frame(height: 30)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.seepBlue)
                                    .shadow(color: .black.opacity(0.15), radius: 1.5, y: 2)
                                    .padding(.horizontal, -18)
                            }
                        }
                        .contentShape(Rectangle().inset(by: -18))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .frame(height: 30)
        .animation(.easeInOut(duration: 0.3), value: selected)
        .sensoryFeedback(.impact(weight: .light), trigger: selected)
    }
}

/// 탭을 `HomeCategoryTabLayout.tabOrigins` 대로 놓는 레이아웃
struct HomeCategoryTabRowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        return CGSize(width: proposal.width ?? HomeCategoryTabLayout.maxRowWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = subviews.map { $0.sizeThatFits(.unspecified).width }
        let origins = HomeCategoryTabLayout.tabOrigins(containerWidth: bounds.width, tabWidths: widths)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + origins[index], y: bounds.midY),
                anchor: .leading,
                proposal: .unspecified
            )
        }
    }
}

/// 정렬 · (가고 싶어요면) 지도 · 검색 · 보기 방식. 홈 목록 위에 붙어 있다 (R-13)
struct HomeFilterBar: View {
    let sortOrder: HomeSortOrder
    let viewType: ViewType
    let isPlaceMapVisible: Bool
    /// "내가 정한 순서"이고 옮길 위시가 2개 이상일 때 (GH-73 R-4)
    var isReorderVisible = false
    var onTapReorder: () -> Void = {}
    let onTapSort: () -> Void
    let onTapPlaceMap: () -> Void
    let onTapSearch: () -> Void
    let onToggleViewType: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onTapSort) {
                HStack(spacing: 2) {
                    Text(verbatim: sortOrder.title)
                        .font(.appleMedium(size: 14))
                    Assets.Icons.icChevronDown.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .foregroundStyle(Color.gray4)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(Strings.Home.Filter.sortAccessibility))

            Spacer(minLength: 0)

            if isReorderVisible {
                Button(action: onTapReorder) {
                    Text(Strings.Home.Reorder.button)
                        .font(.appleExtraBold(size: 14))
                        .foregroundStyle(Color.seepBlue)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if isPlaceMapVisible {
                iconButton(
                    image: Image(systemName: "map"),
                    size: 17,
                    label: Strings.Home.Filter.placeMap,
                    action: onTapPlaceMap
                )
            }
            iconButton(
                image: Image(systemName: "magnifyingglass"),
                size: 18,
                label: Strings.Home.Search.accessibility,
                action: onTapSearch
            )
            Button(action: onToggleViewType) {
                (viewType == .list ? Assets.Icons.icGrid : Assets.Icons.icList).swiftUIImage
                    .resizable()
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(viewType == .list ? Strings.Home.Filter.viewTypeGrid : Strings.Home.Filter.viewTypeList))
        }
        .padding(.leading, 20)
    }

    private func iconButton(image: Image, size: CGFloat, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            image
                .font(.system(size: size))
                .foregroundStyle(Color.gray4)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}
