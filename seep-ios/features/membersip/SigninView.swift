import UIKit

final class SigninView: BaseView {
    let appleButton = SocialButton(socialType: .apple)
    
    let kakaoButton = SocialButton(socialType: .kakao)
    
    let startWithoutSigninButton = UIButton().then {
        $0.setTitle("membership_start_without_signin".localized, for: .normal)
        $0.setTitleColor(.gray4, for: .normal)
        $0.titleLabel?.font = .appleSemiBold(size: 16)
    }
    
    override func setup() {
        self.backgroundColor = UIColor(r: 246, g: 247, b: 249)
        self.addSubViews([
            self.appleButton,
            self.kakaoButton,
            self.startWithoutSigninButton
        ])
    }
    
    override func bindConstraints() {
        self.startWithoutSigninButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-23)
        }
        
        self.kakaoButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(50)
            make.bottom.equalTo(self.startWithoutSigninButton.snp.top).offset(-21)
        }
        
        self.appleButton.snp.makeConstraints { make in
            make.left.equalTo(self.kakaoButton)
            make.right.equalTo(self.kakaoButton)
            make.height.equalTo(self.kakaoButton)
            make.bottom.equalTo(self.kakaoButton.snp.top).offset(-8)
        }
    }
}
