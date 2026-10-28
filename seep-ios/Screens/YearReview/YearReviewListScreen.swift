import SwiftUI

/// 올해 이룬 싶 모두 보기 — 달별 목록 (GH-34 R-6, GH-64 TC-903).
/// 회고 화면 안 스택이나 탭 스택(`.yearReviewList(year:)`)에 쌓인다. 셀을 누르면 감싼 스택에 상세를 쌓는다
struct YearReviewListScreen: View {
    let year: Int

    @State private var viewModel: YearReviewListViewModel

    init(year: Int) {
        self.year = year
        _viewModel = State(initialValue: YearReviewListViewModel(config: .init(year: year)))
    }

    var body: some View {
        YearReviewListContentView(viewModel: viewModel)
    }
}

private struct YearReviewListContentView: View {
    let viewModel: YearReviewListViewModel

    @State private var pushed: AppDestination?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    headline
                        .lineSpacing(9)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 22)
                        .padding(.top, 4)
                        .padding(.bottom, 10)
                    ForEach(Array(viewModel.state.sections.enumerated()), id: \.element.id) { sectionIndex, section in
                        HStack {
                            Text(verbatim: DisplayDate.month(section.month))
                                .font(.appleBold(size: 14))
                                .foregroundStyle(Color.gray5)
                            Spacer()
                            Text(verbatim: Strings.YearReview.countFormat(section.items.count))
                                .font(.appleMedium(size: 14))
                                .foregroundStyle(Color.gray4)
                        }
                        .padding(.horizontal, 2)
                        .frame(height: 42, alignment: .bottom)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 20)

                        VStack(spacing: 10) {
                            ForEach(Array(section.items.enumerated()), id: \.element.id) { itemIndex, item in
                                Button {
                                    viewModel.send(.tapWish(IndexPath(item: itemIndex, section: sectionIndex)))
                                } label: {
                                    YearReviewListRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }
                .frame(maxWidth: SeepLayout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.gray2.ignoresSafeArea())
        // 제목은 본문 헤드라인이 맡고, 바에는 시스템 뒤로 버튼만 둔다
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen(viewModel.screenName)
        .navigationDestination(item: $pushed) { destination in
            DestinationView(destination: destination)
                .seepPushedScreen()
        }
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: viewModel.route) { _, route in
            guard let route else { return }
            switch route {
            case .wishDetail(let id):
                pushed = .wishDetail(id: id, isFinished: true)
            }
            viewModel.send(.routeHandled)
        }
    }

    /// "2026년에 이룬 싶 / **12개 모두 모아봤어요**" — 개수만 tennis-green
    private var headline: Text {
        let count = viewModel.state.totalCount
        let text = Strings.YearReview.List.headlineFormat(String(viewModel.year), count)
        let nsText = text as NSString
        let boldRange = nsText.range(of: Strings.YearReview.List.headlineBoldFormat(count))
        let countRange = nsText.range(of: Strings.YearReview.countFormat(count), options: .backwards)
        guard boldRange.location != NSNotFound, countRange.location != NSNotFound,
              NSLocationInRange(countRange.location, boldRange) else {
            return Text(verbatim: text).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
        }
        let head = nsText.substring(to: boldRange.location)
        let boldHead = nsText.substring(with: NSRange(location: boldRange.location, length: countRange.location - boldRange.location))
        let countText = nsText.substring(with: countRange)
        let boldTail = nsText.substring(from: countRange.location + countRange.length)
        return Text(verbatim: head).font(.appleLight(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: boldHead).font(.appleBold(size: 22)).foregroundStyle(Color.gray5)
            + Text(verbatim: countText).font(.appleBold(size: 22)).foregroundStyle(Color.tennisGreen)
            + Text(verbatim: boldTail).font(.appleBold(size: 22)).foregroundStyle(Color.gray5)
    }
}

/// 이룬 싶 줄: 이모지·제목·(소감 또는 완료일)·완료 체크
private struct YearReviewListRow: View {
    let item: YearReviewListViewModel.Item

    var body: some View {
        HStack(spacing: 14) {
            Text(verbatim: item.wish.emoji)
                .font(.system(size: 30))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.wish.title)
                    .font(.appleSemiBold(size: 16))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
                if let note = item.note {
                    Text(verbatim: note)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                        .lineLimit(1)
                } else {
                    TagBadge(text: item.finishDateText)
                }
            }
            Spacer(minLength: 12)
            Assets.Icons.icCheckOn.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .frame(height: 70)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}
