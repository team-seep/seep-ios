import SwiftUI

/// 계정 화면 (GH-93 R-27 ~ R-29). 마이 탭과 같은 `AccountViewModel`을 쓴다. route 는 마이 탭이 처리한다
struct AccountScreen: View {
    let viewModel: AccountViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let account = viewModel.state.account {
                    header(account)
                }

                Text(Strings.Account.Section.account)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                    .padding(.top, 18)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 2)
                Button {
                    viewModel.send(.tapLogout)
                } label: {
                    SettingsRowView(title: Strings.Account.logout) { EmptyView() }
                }
                .buttonStyle(.plain)
                .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.send(.tapDeleteAccount)
                } label: {
                    deleteRow
                }
                .buttonStyle(.plain)
                .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 18)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: SeepLayout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color.gray2)
        .navigationTitle(Strings.Account.title)
        .navigationBarTitleDisplayMode(.inline)
        .disabled(viewModel.state.isWorking)
        .overlay {
            if viewModel.state.isWorking {
                ProgressView()
            }
        }
        .trackScreen(viewModel.screenName)
        .confirmationDialog(
            Strings.Account.Logout.title,
            isPresented: dialogBinding(.logout),
            titleVisibility: .visible
        ) {
            ForEach(AccountViewModel.logoutChoices, id: \.self) { choice in
                Button(role: choice == .erase ? .destructive : nil) {
                    viewModel.send(.selectLogout(choice))
                } label: {
                    Text(choice == .keep ? Strings.Account.keepLocal : Strings.Account.eraseLocal)
                }
            }
            Button(Strings.Account.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Account.Logout.message)
        }
        .alert(
            Strings.Account.Delete.title,
            isPresented: dialogBinding(.deleteConfirm)
        ) {
            Button(Strings.Account.cancel, role: .cancel) {}
            Button(Strings.Account.Delete.confirm, role: .destructive) {
                viewModel.send(.confirmDeleteAccount)
            }
        } message: {
            Text(Strings.Account.Delete.message)
        }
    }

    private func header(_ account: Account) -> some View {
        VStack(spacing: 8) {
            AppleAvatar(size: 64)
            Text(verbatim: account.email ?? Strings.Account.appleAccount)
                .font(.appleSemiBold(size: 17))
                .foregroundStyle(Color.gray5)
                .lineLimit(1)
                .truncationMode(.middle)
            if let createdAt = account.createdAt {
                Text(Strings.Account.signedUpFormat(DisplayDate.yearMonthDay(createdAt)))
                    .font(.appleRegular(size: 13))
                    .foregroundStyle(Color.gray4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var deleteRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Account.delete)
                    .font(.appleMedium(size: 16))
                    .foregroundStyle(Color.optionRed)
                Text(Strings.Account.deleteDescription)
                    .font(.appleRegular(size: 12))
                    .foregroundStyle(Color.gray4)
            }
            .padding(.vertical, 8)
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private func dialogBinding(_ dialog: AccountViewModel.Dialog) -> Binding<Bool> {
        Binding(
            get: { viewModel.state.dialog == dialog },
            set: { isPresented in
                if !isPresented, viewModel.state.dialog == dialog {
                    viewModel.send(.dismissDialog)
                }
            }
        )
    }
}
