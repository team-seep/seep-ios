import SwiftUI

/// 순서 바꾸기 모드 (GH-73 R-5, R-6). SwiftUI `List` 편집 모드의 기본 손잡이·리프트로 끈다.
/// 헤드라인 "…의 / **순서를 바꾸고 있어요**" · 카테고리 탭(그대로 바꿀 수 있다) · 안내 + 완료 · 고정 위시(흐리게, 끌 수 없음) · 옮길 위시
struct HomeReorderView: View {
    let viewModel: HomeViewModel

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .moveDisabled(true)
            }
            Section {
                ForEach(viewModel.state.pinnedItems) { item in
                    HomeReorderRow(item: item, isPinned: true)
                        .moveDisabled(true)
                        .modifier(HomeReorderRowStyle())
                }
            }
            Section {
                ForEach(viewModel.state.movableItems) { item in
                    HomeReorderRow(item: item, isPinned: false)
                        .modifier(HomeReorderRowStyle())
                }
                .onMove { source, destination in
                    viewModel.send(.moveWish(from: source, to: destination))
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(0)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .environment(\.editMode, .constant(.active))
        .frame(maxWidth: HomeLayout.maxContentWidth)
        .frame(maxWidth: .infinity)
        .background(Color.gray2)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                HeadlineText(text: title, boldPart: Strings.Home.Reorder.titleBold)
                    .padding(.top, 28)
                    .padding(.leading, HomeHeaderLayout.headlineLeading)
                Spacer(minLength: 12)
                HomeIllustrationView(category: viewModel.state.category)
                    .padding(.top, 8)
                    .padding(.trailing, HomeHeaderLayout.illustrationTrailingInset)
            }
            .frame(height: 140, alignment: .top)

            HomeCategoryTabs(selected: viewModel.state.category) { viewModel.send(.selectCategory($0)) }
                .padding(.horizontal, 12)
                .padding(.top, 6)

            HStack(spacing: 0) {
                Text(Strings.Home.Reorder.guide)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                Spacer(minLength: 8)
                Button {
                    viewModel.send(.finishReorder)
                } label: {
                    Text(Strings.Home.Reorder.done)
                        .font(.appleExtraBold(size: 14))
                        .foregroundStyle(Color.seepBlue)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, HomeLayout.horizontalInset + 8)
            .padding(.trailing, HomeLayout.horizontalInset)
        }
    }

    private var title: String {
        switch viewModel.state.category {
        case .wantToDo: return Strings.Home.Reorder.Title.wantToDo
        case .wantToGet: return Strings.Home.Reorder.Title.wantToGet
        case .wantToGo: return Strings.Home.Reorder.Title.wantToGo
        }
    }
}

/// 순서 바꾸기 모드의 한 줄. 체크 원 자리는 편집 모드 손잡이가 차지한다.
/// 고정 위시는 내용 불투명도 0.4 + 핀 + 뱃지 줄 대신 "고정한 위시는 맨 위에 있어요" (R-6)
private struct HomeReorderRow: View {
    let item: HomeWishItem
    let isPinned: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(verbatim: item.wish.emoji)
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 5) {
                HomeWishTitle(wish: item.wish, lineLimit: 1)
                if isPinned {
                    Text(Strings.Home.Reorder.pinnedCaption)
                        .font(.appleMedium(size: 12))
                        .foregroundStyle(Color.gray4)
                } else {
                    HStack(spacing: 7) {
                        HomeDdayBadge(endDate: item.wish.endDate)
                        if let tag = item.tagText {
                            TagBadge(text: tag)
                        }
                        if let progress = item.stepProgress {
                            HomeStepProgress(progress: progress)
                                .padding(.leading, 2)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            if isPinned {
                HomePinIcon()
            }
        }
        .opacity(isPinned ? 0.4 : 1)
        .padding(.horizontal, 14)
        .frame(height: HomeLayout.listRowHeight)
    }
}

/// 리스트 셀처럼 흰 라운드 카드로 그리고 줄 사이를 띄운다
private struct HomeReorderRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: HomeLayout.listSpacing / 2, leading: 0, bottom: HomeLayout.listSpacing / 2, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray1)
                    .padding(.vertical, HomeLayout.listSpacing / 2)
                    .padding(.horizontal, HomeLayout.horizontalInset)
            )
            .padding(.horizontal, HomeLayout.horizontalInset)
    }
}
