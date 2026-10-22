import SwiftUI

/// 정렬 시트: 완료일 가까운순 / 최근 생성순 (높이 56 두 줄, 사이 gray2 선)
struct SortOrderSheet: View {
    let selected: HomeSortOrder
    let onSelect: (HomeSortOrder) -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(.deadlineOrder)
            Rectangle()
                .fill(Color.gray2)
                .frame(height: 1)
            row(.latestOrder)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func row(_ sortOrder: HomeSortOrder) -> some View {
        Button {
            onSelect(sortOrder)
        } label: {
            Text(verbatim: sortOrder.title)
                .font(.appleSemiBold(size: 16))
                .foregroundStyle(Color.gray5)
                .frame(maxWidth: .infinity, minHeight: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(sortOrder == selected ? .isSelected : [])
    }
}

/// 완료 소감 시트: 이모지 40 · "{제목}, / **이루고 나니 어때요?**" · 설명 · 입력 칸 · 글자 수 · 남기기 · 다음에 할게요 (GH-25)
struct FinishNoteSheet: View {
    @Bindable var viewModel: FinishNoteViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: viewModel.wish.emoji)
                .font(.system(size: 40))
                .padding(.top, 24)
            HeadlineText(
                text: Strings.Home.FinishNote.titleFormat(viewModel.wish.title),
                boldPart: Strings.Home.FinishNote.titleBold
            )
            .padding(.top, 10)
            Text(Strings.Home.FinishNote.description)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .padding(.top, 6)

            TextField(
                "",
                text: Binding(
                    get: { viewModel.state.noteText },
                    set: { viewModel.send(.inputNote($0)) }
                ),
                prompt: Text(Strings.Home.FinishNote.placeholder).foregroundStyle(Color.gray3)
            )
            .font(.appleRegular(size: 16))
            .foregroundStyle(Color.gray5)
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit { viewModel.send(.tapSave) }
            .accessibilityLabel(Text(Strings.Home.FinishNote.field))
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, 20)

            Text(verbatim: viewModel.state.countText)
                .font(.appleMedium(size: 12))
                .foregroundStyle(Color.gray4)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)

            SeepCTA(title: Strings.Home.FinishNote.save, isEnabled: viewModel.state.isSaveEnabled, fillsWidth: true) {
                viewModel.send(.tapSave)
            }
            .padding(.top, 22)

            Button {
                viewModel.send(.tapSkip)
            } label: {
                Text(Strings.Home.FinishNote.skip)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: viewModel.route) { _, route in
            if route == .dismiss { dismiss() }
        }
        .alert(
            errorMessage ?? "",
            isPresented: Binding(get: { errorMessage != nil }, set: { _ in }),
            actions: {
                Button(Strings.Home.ErrorAlert.confirm, role: .cancel) {}
            }
        )
    }

    private var errorMessage: String? {
        if case .errorAlert(let message) = viewModel.route { return message }
        return nil
    }
}

/// 새 배지 축하 시트: "위시를 n개나 이뤘어요! / **새 배지를 받았어요**" · 배지 카드들 · 좋아요 · 배지 모아보기 (GH-35)
struct BadgeCelebrationSheet: View {
    let viewModel: BadgeCelebrationViewModel
    @Environment(\.dismiss) private var dismiss

    /// 카드가 이보다 높아지면 카드 영역만 스크롤한다 (카드 약 3장 반)
    private let maxCardsHeight: CGFloat = 400

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadlineText(
                text: Strings.Badge.Celebration.titleFormat(viewModel.finishedCount),
                boldPart: Strings.Badge.Celebration.titleBold
            )
            .padding(.top, 24)

            ViewThatFits(in: .vertical) {
                cards
                ScrollView { cards }
                    .frame(maxHeight: maxCardsHeight)
            }
            .padding(.top, 20)

            SeepCTA(title: Strings.Badge.Celebration.confirm, fillsWidth: true) {
                viewModel.send(.tapConfirm)
            }
            .padding(.top, 24)

            Button {
                viewModel.send(.tapViewBadges)
            } label: {
                Text(Strings.Badge.Celebration.viewBadges)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: viewModel.route) { _, route in
            if route == .dismiss { dismiss() }
        }
    }

    private var cards: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.badges, id: \.type) { badge in
                HStack(spacing: 16) {
                    HomeBadgeMedal(type: badge.type, diameter: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: badge.type.name)
                            .font(.appleSemiBold(size: 16))
                            .foregroundStyle(Color.gray5)
                        Text(verbatim: Strings.Badge.Celebration.cardDescriptionFormat(
                            badge.type.conditionText,
                            badge.earnedDateText ?? ""
                        ))
                        .font(.appleMedium(size: 12))
                        .foregroundStyle(Color.gray4)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// 얻은 배지 메달: 흰 원 + tennis-green 3pt 링 + 숫자 / 카테고리 일러스트 / "D-day" (GH-35 R-1)
struct HomeBadgeMedal: View {
    let type: BadgeType
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray1)
            Circle()
                .strokeBorder(Color.tennisGreen, lineWidth: 3)
            switch type.medal {
            case .number(let number):
                Text(verbatim: "\(number)")
                    .font(.appleBold(size: 22))
                    .foregroundStyle(Color.gray5)
            case .category(let category):
                category.illustration
                    .resizable()
                    .scaledToFit()
                    .frame(width: (diameter * 36 / 56).rounded(), height: (diameter * 36 / 56).rounded())
            case .dday:
                Text(Strings.Badge.dday)
                    .font(.appleExtraBold(size: 14))
                    .foregroundStyle(Color.gray5)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}
