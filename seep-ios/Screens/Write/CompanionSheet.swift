import SwiftUI

/// "이 싶은 / 누구랑 하고 싶어요?" 시트 (GH-122 R-1). 고른 사람 → 이름 입력 → 전에 적은 사람 → 정했어요 / 혼자 할래요
struct CompanionSheet: View {
    @Bindable var viewModel: CompanionSheetViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?
    @FocusState private var isFieldFocused: Bool

    private var state: CompanionSheetViewModel.State { viewModel.state }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Companion.Sheet.titleLead)
                    .font(.appleLight(size: 22))
                Text(Strings.Companion.Sheet.title)
                    .font(.appleBold(size: 22))
            }
            .foregroundStyle(Color.gray5)
            .padding(.top, 28)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !state.selected.isEmpty {
                        chipGroup(title: Strings.Companion.Sheet.selected) {
                            ForEach(state.selected) { person in
                                Button {
                                    viewModel.send(.tapSelected(person))
                                } label: {
                                    CompanionChip(name: person.name, isSelected: true, showsRemove: true)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(Strings.Companion.Sheet.removeFormat(person.name)))
                            }
                        }
                    }
                    if !state.isFull {
                        nameField
                    }
                    if !state.suggested.isEmpty {
                        chipGroup(title: Strings.Companion.Sheet.recent) {
                            ForEach(state.suggested) { person in
                                Button {
                                    viewModel.send(.tapRecent(person))
                                } label: {
                                    CompanionChip(name: person.name, isSelected: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            SeepCTA(title: Strings.Companion.Sheet.done, fillsWidth: true) {
                viewModel.send(.tapDone)
            }
            .padding(.top, 16)
            Button {
                viewModel.send(.tapAlone)
            } label: {
                Text(Strings.Companion.Sheet.alone)
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
        .onChange(of: viewModel.route) { _, route in handle(route) }
    }

    private var nameField: some View {
        TextField(
            "",
            text: Binding(get: { state.nameInput }, set: { viewModel.send(.inputName($0)) }),
            prompt: Text(Strings.Companion.Sheet.placeholder).foregroundStyle(Color.gray3)
        )
        .font(.appleRegular(size: 16))
        .foregroundStyle(Color.gray5)
        .tint(Color.seepBlue)
        .submitLabel(.done)
        .autocorrectionDisabled()
        .focused($isFieldFocused)
        .onSubmit {
            viewModel.send(.submitName)
            // 이어서 다음 사람을 적을 수 있게 커서를 남긴다
            isFieldFocused = true
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }

    private func chipGroup<Chips: View>(title: String, @ViewBuilder chips: () -> Chips) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: title)
                .font(.appleMedium(size: 14))
                .foregroundStyle(Color.gray4)
            WishFormFlowLayout(spacing: 8) {
                chips()
            }
        }
    }

    private func handle(_ route: CompanionSheetViewModel.Route?) {
        guard let route else { return }
        switch route {
        case .toast(let message):
            toastCenter?.show(message)
        case .dismiss:
            dismiss()
        }
        viewModel.send(.routeHandled)
    }
}

/// 사람 칩 (GH-122). 탭 알약 규칙: 보통은 category-track 바탕 + seep-blue 글자, 고르면 seep-blue 바탕 + 흰 ExtraBold 14
struct CompanionChip: View {
    let name: String
    let isSelected: Bool
    var showsRemove = false

    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: name)
                .lineLimit(1)
            if showsRemove {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .font(isSelected ? .appleExtraBold(size: 14) : .appleBold(size: 14))
        .foregroundStyle(isSelected ? Color.onAccent : Color.seepBlue)
        .padding(.horizontal, 14)
        .frame(minHeight: 36)
        .background(isSelected ? Color.seepBlue : Color.categoryTrack, in: Capsule())
        .contentShape(Capsule())
    }
}
