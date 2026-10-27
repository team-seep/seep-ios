import SwiftUI

/// 여러 개 골라 지우기 모드 (GH-86 R-3~R-5).
/// 헤드라인 "…을 / **골라서 지워요**" · 카테고리 탭 · "취소 · n개 선택됨 · 전체 선택" · 체크 리스트 · 하단 "n개 삭제"
struct HomeSelectionView: View {
    let viewModel: HomeViewModel

    private var state: HomeViewModel.State { viewModel.state }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header
                VStack(spacing: HomeLayout.listSpacing) {
                    ForEach(state.selectableItems) { item in
                        HomeSelectionRow(item: item, isSelected: state.selectedIds.contains(item.id))
                            .onTapGesture { viewModel.send(.tapWish(item.wish)) }
                    }
                }
                .padding(.horizontal, HomeLayout.horizontalInset)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .frame(maxWidth: HomeLayout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.gray2.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            deleteButton
        }
        .sensoryFeedback(.selection, trigger: state.selectedIds)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                HeadlineText(text: title, boldPart: Strings.Home.Select.titleBold)
                    .padding(.top, 28)
                    .padding(.leading, HomeHeaderLayout.headlineLeading)
                Spacer(minLength: 12)
                HomeIllustrationView(category: state.category)
                    .padding(.top, 8)
                    .padding(.trailing, HomeHeaderLayout.illustrationTrailingInset)
            }
            .frame(height: 140, alignment: .top)

            HomeCategoryTabs(selected: state.category) { viewModel.send(.selectCategory($0)) }
                .padding(.horizontal, 12)
                .padding(.top, 6)

            HStack(spacing: 0) {
                textButton(Strings.Home.Select.cancel, color: Color.gray4, isBold: false) {
                    viewModel.send(.cancelSelection)
                }
                Spacer(minLength: 8)
                Text(Strings.Home.Select.countFormat(state.selectedIds.count))
                    .font(.appleBold(size: 15))
                    .foregroundStyle(Color.gray5)
                Spacer(minLength: 8)
                textButton(Strings.Home.Select.all, color: Color.seepBlue, isBold: true) {
                    viewModel.send(.selectAll)
                }
            }
            .padding(.horizontal, HomeLayout.horizontalInset)
        }
    }

    private var deleteButton: some View {
        let count = state.selectedIds.count
        return Button {
            viewModel.send(.tapDeleteSelected)
        } label: {
            Text(Strings.Home.Select.deleteFormat(count))
                .font(.appleExtraBold(size: 17))
                .foregroundStyle(Color.gray1)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(count > 0 ? Color.optionRed : Color.ctaDisabled, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .padding(.horizontal, HomeLayout.horizontalInset)
        .padding(.bottom, 12)
        .frame(maxWidth: HomeLayout.maxContentWidth)
    }

    private func textButton(_ title: String, color: Color, isBold: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(isBold ? .appleExtraBold(size: 14) : .appleMedium(size: 14))
                .foregroundStyle(color)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        switch state.category {
        case .wantToDo: return Strings.Home.Select.Title.wantToDo
        case .wantToGet: return Strings.Home.Select.Title.wantToGet
        case .wantToGo: return Strings.Home.Select.Title.wantToGo
        }
    }
}

/// 선택 모드 한 줄. 체크 원 자리에 선택 표시, 고르면 seep-blue 테두리 (GH-86 R-3)
private struct HomeSelectionRow: View {
    let item: HomeWishItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(verbatim: item.wish.emoji)
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    HomeWishTitle(wish: item.wish, lineLimit: 1)
                    if item.isPinned {
                        HomePinIcon()
                    }
                }
                HStack(spacing: 7) {
                    HomeDdayBadge(endDate: item.wish.endDate)
                    if let tag = item.tagText {
                        TagBadge(text: tag)
                    }
                }
            }
            Spacer(minLength: 0)
            ZStack {
                if isSelected {
                    Circle().fill(Color.seepBlue)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.gray1)
                } else {
                    Circle().strokeBorder(Color.gray3, lineWidth: 2)
                }
            }
            .frame(width: 26, height: 26)
            .padding(.trailing, 16)
            .accessibilityHidden(true)
        }
        .padding(.leading, 14)
        .frame(height: HomeLayout.listRowHeight)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.seepBlue, lineWidth: 2)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
