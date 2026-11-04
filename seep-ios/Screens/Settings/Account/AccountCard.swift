import SwiftUI

/// 마이 탭 맨 위 계정 카드 (GH-93 R-24). 로그인은 여기서만 권한다(R-25)
struct AccountCard: View {
    let viewModel: AccountViewModel

    var body: some View {
        Group {
            if let account = viewModel.state.account {
                Button {
                    viewModel.send(.tapAccountCard)
                } label: {
                    memberCard(account)
                }
                .buttonStyle(.plain)
            } else {
                guestCard
            }
        }
        .padding(.top, 8)
    }

    private var guestCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.gray3)
                    .frame(width: 44, height: 44)
                    .background(Color.gray2, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Strings.Account.Card.guestTitle)
                        .font(.appleBold(size: 17))
                        .foregroundStyle(Color.gray5)
                    Text(Strings.Account.Card.guestDescription)
                        .font(.appleRegular(size: 13))
                        .foregroundStyle(Color.gray4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            AppleContinueButton(isWorking: viewModel.state.isWorking) {
                viewModel.send(.tapSignIn)
            }
            Text(Strings.Account.Card.guestNote)
                .font(.appleRegular(size: 12))
                .foregroundStyle(Color.gray4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
    }

    private func memberCard(_ account: Account) -> some View {
        HStack(spacing: 12) {
            AppleAvatar(size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: account.email ?? Strings.Account.appleAccount)
                    .font(.appleSemiBold(size: 16))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(Strings.Account.Card.memberSubtitle)
                    .font(.appleRegular(size: 13))
                    .foregroundStyle(Color.gray4)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.gray3)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}

/// "Apple로 계속하기". 시스템 버튼은 앱 개발 언어(en)로만 나와 직접 그린다(HIG 허용 모양: 라이트 검정·다크 흰 바탕 + Apple 로고, gray5/gray1 반전)
struct AppleContinueButton: View {
    let isWorking: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isWorking {
                    ProgressView()
                        .tint(Color.gray1)
                } else {
                    Image(systemName: "apple.logo")
                }
                Text(isWorking ? Strings.Account.Card.signingIn : Strings.Account.Card.appleButton)
                    .font(.appleSemiBold(size: 16))
            }
            .foregroundStyle(Color.gray1)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.gray5, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }
}

struct AppleAvatar: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "apple.logo")
            .font(.system(size: size * 0.45))
            .foregroundStyle(Color.gray1)
            .frame(width: size, height: size)
            .background(Color.gray5, in: Circle())
            .accessibilityHidden(true)
    }
}
