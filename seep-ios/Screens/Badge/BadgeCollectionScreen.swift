import SwiftUI

/// 배지 모아보기 (GH-35 R-5, GH-64 TC-801). 싶 탭의 배지 축하 시트·이룬 싶 탭 배지 카드에서 push 된다
struct BadgeCollectionScreen: View {
    @State private var viewModel = BadgeCollectionViewModel()
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                dismiss()
            } label: {
                Assets.Icons.icChevronBack.swiftUIImage
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Strings.Badge.Collection.back))
            .padding(.leading, 10)
            .padding(.top, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    titleText
                        .lineSpacing(9)
                        .padding(.horizontal, 22)
                        .padding(.top, 14)
                    Text(Strings.Badge.Collection.description)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(viewModel.state.badges, id: \.type) { badge in
                            BadgeCard(badge: badge)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: SeepLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.gray2.ignoresSafeArea())
        .trackScreen(viewModel.screenName)
        .onAppear { viewModel.send(.onAppear) }
    }

    /// "이룬 싶이 모여 / 배지 **3개**를 모았어요!" — 개수만 tennis-green, 뒷부분 Bold
    private var titleText: Text {
        let count = viewModel.state.earnedCount
        let text = Strings.Badge.Collection.titleFormat(count)
        let nsText = text as NSString
        let boldRange = nsText.range(of: Strings.Badge.Collection.titleBold, options: .backwards)
        let highlightRange = nsText.range(of: Strings.Badge.Collection.titleHighlightFormat(count), options: .backwards)
        guard boldRange.location != NSNotFound, highlightRange.location != NSNotFound,
              highlightRange.location + highlightRange.length <= boldRange.location else {
            return Text(verbatim: text).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
        }
        let head = nsText.substring(to: highlightRange.location)
        let highlight = nsText.substring(with: highlightRange)
        let middle = nsText.substring(with: NSRange(
            location: highlightRange.location + highlightRange.length,
            length: boldRange.location - highlightRange.location - highlightRange.length
        ))
        let bold = nsText.substring(from: boldRange.location)
        return Text(verbatim: head).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: highlight).font(.appleBold(size: 22)).foregroundStyle(Color.tennisGreen)
            + Text(verbatim: middle).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: bold).font(.appleBold(size: 22)).foregroundStyle(Color.gray5)
    }
}

/// 그리드 칸 하나: gray1 카드, 메달 56 + 이름 + 얻은 날 또는 진행도·조건 문구 (GH-35 R-5)
private struct BadgeCard: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 0) {
            BadgeMedal(type: badge.type, isEarned: badge.isEarned, diameter: 56, fillColor: .gray2)
                .padding(.top, 16)
            Text(verbatim: badge.type.name)
                .font(.appleBold(size: 14))
                .foregroundStyle(badge.isEarned ? Color.gray5 : Color.gray4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 10)
            Text(verbatim: description)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(badge.type.name), \(description)"))
    }

    private var description: String {
        badge.earnedDateText ?? badge.lockedDescription
    }
}

/// 배지 메달: 원형 바탕 + 3pt 링 + 숫자·카테고리 일러스트·"D-day" (GH-35 R-1, R-5).
/// 얻은 배지는 tennis-green 링, 잠긴 배지는 gray2-5 링에 내용을 0.3으로 흐린다
struct BadgeMedal: View {
    let type: BadgeType
    let isEarned: Bool
    var diameter: CGFloat = 56
    var fillColor: Color = .gray2

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
            Circle()
                .strokeBorder(isEarned ? Color.tennisGreen : Color.gray2_5, lineWidth: 3)
            content
                .opacity(isEarned ? 1 : 0.3)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch type.medal {
        case .number(let number):
            Text(verbatim: "\(number)")
                .font(.appleBold(size: 22))
                .foregroundStyle(Color.gray5)
        case .category(let category):
            category.illustration
                .resizable()
                .scaledToFit()
                // 메달 지름 대비 일러스트 크기 (56 → 36)
                .frame(width: (diameter * 36 / 56).rounded(), height: (diameter * 36 / 56).rounded())
        case .dday:
            Text(Strings.Badge.dday)
                .font(.appleExtraBold(size: 14))
                .foregroundStyle(Color.gray5)
        }
    }
}
